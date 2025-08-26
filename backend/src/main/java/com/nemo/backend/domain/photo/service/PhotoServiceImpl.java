package com.nemo.backend.domain.photo.service;

import com.nemo.backend.domain.photo.dto.PhotoResponseDto;
import com.nemo.backend.domain.photo.entity.Photo;
import com.nemo.backend.domain.photo.repository.PhotoRepository;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.CookieHandler;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Map;
import java.util.LinkedHashMap;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.stream.Collectors;

@Service
@Transactional
public class PhotoServiceImpl implements PhotoService {

    // ===== 설정/상수 =====
    private static final int CONNECT_TIMEOUT_MS = 5000;
    private static final int READ_TIMEOUT_MS = 10000;
    private static final int MAX_REDIRECTS = 5;
    private static final int MAX_HTML_FOLLOW = 2;                 // og:image / <img> 추적 최대 단계
    private static final long MAX_IMAGE_BYTES = 10L * 1024 * 1024; // 10MB
    private static final String USER_AGENT = "nemo-app/1.0 (+https://nemo)";
    private static final String[] ALLOWED_SCHEMES = {"http", "https"};

    private final PhotoRepository photoRepository;
    private final PhotoStorage storage;
    private final QrDecoder qrDecoder;

    @Autowired
    public PhotoServiceImpl(
            PhotoRepository photoRepository,
            PhotoStorage storage,
            QrDecoder qrDecoder
    ) {
        this.photoRepository = photoRepository;
        this.storage = storage;
        this.qrDecoder = qrDecoder;
    }

    @Override
    public PhotoResponseDto upload(Long userId, MultipartFile qrFile) {
        if (qrFile == null || qrFile.isEmpty()) {
            throw new IllegalArgumentException("QR 파일이 없습니다.");
        }

        // 1) QR 디코드
        String qrPayload = qrDecoder.decode(qrFile);
        if (qrPayload == null || qrPayload.isBlank()) {
            throw new InvalidQrException("QR 코드를 해석할 수 없습니다.");
        }

        // 2) (선택) 만료 검사: payload가 숫자면 만료시각으로 간주
        if (qrPayload.chars().allMatch(Character::isDigit)) {
            long expiryMillis = Long.parseLong(qrPayload.trim());
            if (System.currentTimeMillis() > expiryMillis) {
                throw new InvalidQrException("만료된 QR 코드입니다.");
            }
        }

        // 3) 중복 방지용 해시
        String qrHash = sha256Hex(qrPayload);
        photoRepository.findByQrHash(qrHash).ifPresent(existing -> {
            throw new DuplicateQrException("이미 업로드된 QR 코드입니다.");
        });

        // 4) payload가 URL이면 외부에서 이미지를 가져와 저장 (HTML → 이미지/다운로드 버튼 추적 지원)
        String photoUrl;
        try {
            if (looksLikeUrl(qrPayload)) {
                photoUrl = fetchPhotoFromQrPayload(qrPayload);
            } else {
                // URL이 아닐 때의 전략이 필요하다면 이 분기를 구현하세요.
                photoUrl = storeFromNonUrlPayload(qrPayload);
            }
        } catch (IOException e) {
            throw new RuntimeException("외부 사진을 가져오는 데 실패했습니다.", e);
        }

        // 5) 저장 및 응답
        Photo photo = new Photo(userId, null, photoUrl, qrHash);
        Photo saved = photoRepository.save(photo);
        return new PhotoResponseDto(saved);
    }

    /**
     * QR payload를 URL로 간주하여 외부에서 이미지를 다운로드합니다.
     * - 3xx 리다이렉트 최대 5회 추적
     * - image/* 인 경우만 바로 저장
     * - text/html 인 경우 Jsoup으로 og:image/첫 번째 <img> 또는 다운로드 버튼/폼을 추적 (최대 2회)
     * - 쿠키/Referer 유지, 사이즈/스킴/타임아웃 방어 로직 포함
     */
    private String fetchPhotoFromQrPayload(String startUrl) throws IOException {
        // 세션 유지 (쿠키)
        CookieManager cm = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        CookieHandler.setDefault(cm);

        String current = startUrl;
        int htmlFollow = 0;

        for (int redirectCount = 0; redirectCount <= MAX_REDIRECTS; redirectCount++) {
            URL url = new URL(current);
            if (!isAllowedScheme(url)) {
                throw new IOException("Unsupported URL scheme: " + url.getProtocol());
            }

            HttpURLConnection conn = open(current, "GET", null, startUrl);
            int code = conn.getResponseCode();

            // 리다이렉트 수동 처리
            if (code / 100 == 3) {
                String location = conn.getHeaderField("Location");
                if (location == null || location.isBlank()) {
                    throw new IOException("Redirect without Location");
                }
                current = new URL(url, location).toString();
                continue;
            }

            String contentType = safeLower(conn.getContentType());
            // 바로 이미지면 저장
            if (contentType != null && contentType.startsWith("image/")) {
                try (InputStream in = boundedStream(conn)) {
                    String ext = extractExtensionFromContentType(contentType);
                    MultipartFile downloaded = toMultipart(in, contentType, ext);
                    return storage.store(downloaded);
                }
            }
            // Content-Disposition 으로 파일 응답일 수도 있음
            String cd = conn.getHeaderField("Content-Disposition");
            if (cd != null && cd.toLowerCase(Locale.ROOT).contains("attachment")) {
                try (InputStream in = boundedStream(conn)) {
                    String ct = contentType != null ? contentType : "application/octet-stream";
                    String ext = extractExtensionFromContentType(ct);
                    MultipartFile downloaded = toMultipart(in, ct, ext);
                    return storage.store(downloaded);
                }
            }

            // HTML → 이미지/다운로드 링크/폼 추적
            if (contentType != null && contentType.startsWith("text/html")) {
                if (htmlFollow >= MAX_HTML_FOLLOW) {
                    throw new IOException("HTML follow limit reached");
                }
                String html = readAll(conn.getInputStream());

                // (1) GET 링크 후보 찾기
                String candidate = findDownloadUrlInHtml(html, current);
                if (candidate != null && isProbablyGet(candidate)) {
                    current = new URL(url, candidate).toString();
                    htmlFollow++;
                    continue;
                }

                // (2) 폼 제출(POST) 필요 시 시도
                PostForm form = findPostForm(html);
                if (form != null) {
                    String actionAbs = new URL(url, form.action != null ? form.action : current).toString();
                    String body = form.encode();
                    HttpURLConnection post = open(actionAbs, "POST", body, current);
                    String ct2 = safeLower(post.getContentType());
                    if (ct2 != null && ct2.startsWith("image/")) {
                        try (InputStream in = boundedStream(post)) {
                            String ext = extractExtensionFromContentType(ct2);
                            MultipartFile mf = toMultipart(in, ct2, ext);
                            return storage.store(mf);
                        }
                    }
                    String cd2 = post.getHeaderField("Content-Disposition");
                    if (cd2 != null && cd2.toLowerCase(Locale.ROOT).contains("attachment")) {
                        try (InputStream in = boundedStream(post)) {
                            String ct = ct2 != null ? ct2 : "application/octet-stream";
                            String ext = extractExtensionFromContentType(ct);
                            MultipartFile mf = toMultipart(in, ct, ext);
                            return storage.store(mf);
                        }
                    }
                    // POST 결과가 다시 HTML이면 한 번 더 링크 찾기
                    String html2 = readAll(post.getInputStream());
                    String cand2 = findDownloadUrlInHtml(html2, actionAbs);
                    if (cand2 != null) {
                        current = new URL(new URL(actionAbs), cand2).toString();
                        htmlFollow++;
                        continue;
                    }
                    throw new IOException("No image URL found in HTML after POST");
                }

                // (3) GET 링크가 있었는데 javascript: 이었으면 보정
                if (candidate != null) {
                    current = new URL(url, candidate).toString();
                    htmlFollow++;
                    continue;
                }

                throw new IOException("No image URL found in HTML");
            }

            throw new IOException("Unsupported content type: " + contentType);
        }

        throw new IOException("Too many redirects");
    }

    // ===== 헬퍼/유틸 메소드 =====

    private HttpURLConnection open(String url, String method, String body, String referer) throws IOException {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setInstanceFollowRedirects(false);
        conn.setConnectTimeout(CONNECT_TIMEOUT_MS);
        conn.setReadTimeout(READ_TIMEOUT_MS);
        conn.setRequestProperty("User-Agent", USER_AGENT);
        conn.setRequestProperty("Accept", "text/html,application/xhtml+xml,application/xml,image/avif,image/webp,image/*;q=0.9,*/*;q=0.8");
        conn.setRequestProperty("Accept-Language", "ko,ko-KR;q=0.9,en-US;q=0.8,en;q=0.7");
        if (referer != null) conn.setRequestProperty("Referer", referer);
        conn.setRequestMethod(method);
        if ("POST".equalsIgnoreCase(method) && body != null) {
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            conn.setDoOutput(true);
            conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
            conn.setRequestProperty("Content-Length", String.valueOf(bytes.length));
            try (OutputStream os = conn.getOutputStream()) {
                os.write(bytes);
            }
        }
        conn.connect();
        return conn;
    }

    private boolean looksLikeUrl(String s) {
        String t = s.trim().toLowerCase(Locale.ROOT);
        return t.startsWith("http://") || t.startsWith("https://");
    }

    private boolean isAllowedScheme(URL url) {
        String p = url.getProtocol().toLowerCase(Locale.ROOT);
        for (String s : ALLOWED_SCHEMES) {
            if (p.equals(s)) return true;
        }
        return false;
    }

    private boolean isRedirect(int code) {
        return code >= 300 && code < 400;
    }

    private String resolve(URL base, String location) throws IOException {
        // 상대경로 보정
        return new URL(base, location).toString();
    }

    private String safeLower(String s) {
        return (s == null) ? null : s.toLowerCase(Locale.ROOT);
    }

    /** HTML에서 og:image 또는 '이미지 다운로드' 흐름의 URL을 찾아 절대 URL로 반환 */
    private String tryExtractImageFromHtml(HttpURLConnection conn, URL baseUrl) {
        try (InputStream in = conn.getInputStream()) {
            String html = new String(in.readAllBytes(), StandardCharsets.UTF_8);
            Document doc = Jsoup.parse(html);

            // 1) og:image 우선
            Element og = doc.selectFirst("meta[property=og:image], meta[name=og:image]");
            if (og != null) {
                String c = og.hasAttr("content") ? og.attr("content") : null;
                if (c != null && !c.isBlank()) {
                    return new URL(baseUrl, c).toString(); // 상대경로 보정
                }
            }
            // 2) 첫 번째 <img>
            Element img = doc.selectFirst("img[src]");
            if (img != null) {
                String src = img.attr("src");
                if (src != null && !src.isBlank()) {
                    return new URL(baseUrl, src).toString();
                }
            }
        } catch (Exception ignored) {}
        return null;
    }

    /** HTML에서 '이미지 다운로드' 흐름을 추정해 URL을 찾는다 */
    private String findDownloadUrlInHtml(String html, String baseUrl) {
        Document doc = Jsoup.parse(html, baseUrl);

        // 1) 메타 이미지들
        String m = firstMeta(doc,
                "meta[property=og:image]",
                "meta[name=og:image]",
                "meta[property=og:image:url]",
                "meta[property=og:image:secure_url]",
                "meta[name=twitter:image]",
                "meta[name=twitter:image:src]",
                "meta[itemprop=image]"
        );
        if (m != null) return m;

        // 2) 명시적 다운로드 링크/버튼
        Elements aTags = doc.select("a[download], a#download, a.button:matches((?i)image), a:matches((?i)다운로드|download)");
        for (Element a : aTags) {
            String href = a.attr("href");
            if (!href.isBlank()) return href;
            String dh = a.attr("data-href");
            if (!dh.isBlank()) return dh;
            String du = a.attr("data-url");
            if (!du.isBlank()) return du;
        }

        Elements btns = doc.select("button, .btn, .button");
        for (Element b : btns) {
            String text = b.text();
            if (!(text.toLowerCase(Locale.ROOT).contains("image")
                    || text.contains("이미지") || text.contains("다운로드"))) continue;
            String u = b.attr("data-href");
            if (!u.isBlank()) return u;
            u = b.attr("data-url");
            if (!u.isBlank()) return u;
        }

        // 3) meta refresh
        Element refresh = doc.selectFirst("meta[http-equiv=refresh][content]");
        if (refresh != null) {
            String content = refresh.attr("content"); // "0;url=/download"
            int p = content.toLowerCase(Locale.ROOT).indexOf("url=");
            if (p >= 0) return content.substring(p + 4).trim();
        }

        // 4) 스크립트 내 정규식
        for (Element s : doc.select("script")) {
            String code = s.data();
            Matcher m1 = Pattern.compile("(https?://[^\\s\"'>)]+\\.(?:png|jpe?g|gif|webp))",
                    Pattern.CASE_INSENSITIVE).matcher(code);
            if (m1.find()) return m1.group(1);

            Matcher m2 = Pattern.compile("(?:href|url)\\s*[:=]\\s*[\"']([^\"']+?download[^\"']*)[\"']",
                    Pattern.CASE_INSENSITIVE).matcher(code);
            if (m2.find()) return m2.group(1);
        }

        // 5) 마지막 fallback: 첫 번째 <img>
        Element img = doc.selectFirst("img[src]");
        if (img != null) return img.attr("src");

        return null;
    }

    private String firstMeta(Document doc, String... selectors) {
        for (String sel : selectors) {
            Element el = doc.selectFirst(sel);
            if (el != null) {
                String c = el.attr("content");
                if (c != null && !c.isBlank()) return c;
            }
        }
        return null;
    }

    /** Content-Length로 사전 차단 + 스트림 읽는 동안 사이즈 제한 */
    private InputStream boundedStream(HttpURLConnection conn) throws IOException {
        long len = conn.getContentLengthLong();
        if (len > 0 && len > MAX_IMAGE_BYTES) {
            throw new IOException("Image too large: " + len);
        }
        // Content-Length가 없으면 읽으면서 제한
        InputStream raw = conn.getInputStream();
        return new LimitedInputStream(raw, MAX_IMAGE_BYTES);
    }

    /** image/png → .png, image/jpeg → .jpg, 그 외 서브타입 → .subtype */
    private String extractExtensionFromContentType(String contentType) {
        if (contentType == null) return ".img";
        int slash = contentType.indexOf('/');
        if (slash >= 0 && slash + 1 < contentType.length()) {
            String subtype = contentType.substring(slash + 1).toLowerCase(Locale.ROOT);
            if (subtype.contains("jpeg") || subtype.contains("jpg")) return ".jpg";
            if (subtype.contains("png"))  return ".png";
            if (subtype.contains("gif"))  return ".gif";
            if (subtype.contains("webp")) return ".webp";
            return "." + subtype.replaceAll("[^a-z0-9.+-]", "");
        }
        return ".img";
    }

    /** InputStream 전체를 UTF-8 문자열로 읽기 */
    private String readAll(InputStream in) throws IOException {
        try (in) {
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }


    /** InputStream -> MultipartFile (메모리 보관) */
    private MultipartFile toMultipart(InputStream in, String contentType, String ext) throws IOException {
        byte[] data = in.readAllBytes();
        if (data.length > MAX_IMAGE_BYTES) {
            throw new IOException("Image too large after download");
        }
        return new MultipartFile() {
            @Override public String getName() { return "photo"; }
            @Override public String getOriginalFilename() { return java.util.UUID.randomUUID() + ext; }
            @Override public String getContentType() { return contentType; }
            @Override public boolean isEmpty() { return data.length == 0; }
            @Override public long getSize() { return data.length; }
            @Override public byte[] getBytes() { return data; }
            @Override public java.io.InputStream getInputStream() {
                return new java.io.ByteArrayInputStream(data);
            }
            @Override public void transferTo(java.io.File dest) throws IOException {
                try (var fos = new java.io.FileOutputStream(dest)) {
                    fos.write(data);
                }
            }
        };
    }

    /** 다운로드 중 용량 제한을 강제하는 래퍼 */
    private static class LimitedInputStream extends java.io.FilterInputStream {
        private long remaining;
        protected LimitedInputStream(InputStream in, long maxBytes) {
            super(in);
            this.remaining = maxBytes;
        }
        @Override
        public int read() throws IOException {
            if (remaining <= 0) throw new IOException("Image exceeds limit");
            int b = super.read();
            if (b != -1) remaining--;
            return b;
        }
        @Override
        public int read(byte[] b, int off, int len) throws IOException {
            if (remaining <= 0) throw new IOException("Image exceeds limit");
            len = (int) Math.min(len, remaining);
            int n = super.read(b, off, len);
            if (n > 0) remaining -= n;
            return n;
        }
    }

    /** 다운로드용 폼 표현 */
    private static class PostForm {
        String action;
        Map<String, String> fields = new LinkedHashMap<>();
        String encode() {
            return fields.entrySet().stream()
                    .map(e -> enc(e.getKey()) + "=" + enc(e.getValue()))
                    .collect(Collectors.joining("&"));
        }
        private static String enc(String s) {
            try { return URLEncoder.encode(s, StandardCharsets.UTF_8); }
            catch (Exception e) { return ""; }
        }
    }

    /** HTML에서 POST 폼(다운로드용) 탐색 및 데이터 구성 */
    private PostForm findPostForm(String html) {
        Document doc = Jsoup.parse(html);
        Element form = doc.selectFirst("form[method=post], form:matches((?i)download)");
        if (form == null) return null;
        PostForm pf = new PostForm();
        pf.action = form.hasAttr("action") ? form.attr("action") : null;
        for (Element in : form.select("input[name]")) {
            String name = in.attr("name");
            String val = in.hasAttr("value") ? in.attr("value") : "";
            pf.fields.put(name, val);
        }
        Element submit = form.selectFirst("button[type=submit], input[type=submit]");
        if (submit != null && submit.hasAttr("name")) {
            pf.fields.put(submit.attr("name"), submit.hasAttr("value") ? submit.attr("value") : "");
        }
        return pf;
    }

    private boolean isProbablyGet(String href) {
        return href != null && !href.trim().toLowerCase(Locale.ROOT).startsWith("javascript:");
    }

    // URL이 아닌 payload 처리 전략이 필요하면 구현
    private String storeFromNonUrlPayload(String payload) {
        // 예: payload 기반 생성/업로드 등
        return "";
    }

    private String sha256Hex(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(input.getBytes()));
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PhotoResponseDto> list(Long userId, Pageable pageable) {
        return photoRepository
                .findByUserIdAndDeletedIsFalseOrderByCreatedAtDesc(userId, pageable)
                .map(PhotoResponseDto::new);
    }

    @Override
    public void delete(Long userId, Long photoId) {
        Photo photo = photoRepository.findById(photoId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사진입니다."));
        if (!photo.getUserId().equals(userId)) {
            throw new IllegalStateException("삭제 권한이 없습니다.");
        }
        photo.setDeleted(true);
        photoRepository.save(photo);
    }
}
