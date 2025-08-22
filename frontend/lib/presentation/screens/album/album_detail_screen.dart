import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/album_provider.dart';
import 'package:frontend/providers/photo_provider.dart';
import 'package:frontend/services/album_api.dart';
import 'select_album_photos_screen.dart';
import 'package:frontend/services/photo_api.dart';
import 'package:frontend/presentation/screens/photo/photo_detail_screen.dart';
import 'package:frontend/presentation/screens/photo/photo_edit_screen.dart';
import 'package:frontend/presentation/screens/photo/photo_viewer_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final int albumId;
  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  bool _working = false;

  Future<void> _addPhotos() async {
    final selected = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(builder: (_) => const SelectAlbumPhotosScreen()),
    );
    if (selected == null || selected.isEmpty) return;
    setState(() => _working = true);
    try {
      await AlbumApi.addPhotos(albumId: widget.albumId, photoIds: selected);
      if (!mounted) return;
      context.read<AlbumProvider>().addPhotos(widget.albumId, selected);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진이 추가되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('추가 실패: $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _removeSelected(List<int> photoIds) async {
    if (photoIds.isEmpty) return;
    setState(() => _working = true);
    try {
      await AlbumApi.removePhotos(albumId: widget.albumId, photoIds: photoIds);
      if (!mounted) return;
      context.read<AlbumProvider>().removePhotos(widget.albumId, photoIds);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진이 삭제되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showPhotoActions(
    BuildContext context,
    PhotoItem p,
    VoidCallback refreshSelection,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('상세'),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DraggableScrollableSheet(
                        initialChildSize: 0.6,
                        minChildSize: 0.4,
                        maxChildSize: 0.9,
                        expand: false,
                        builder: (c, ctrl) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: PhotoDetailSheet(photoId: p.photoId),
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('수정'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoEditScreen(photoId: p.photoId),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('삭제'),
                  onTap: () async {
                    Navigator.pop(context);
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('삭제하시겠어요?'),
                        content: const Text('이 사진은 영구 삭제됩니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    try {
                      await PhotoApi().deletePhoto(p.photoId);
                      if (!mounted) return;
                      context.read<PhotoProvider>().removeById(p.photoId);
                      context.read<AlbumProvider>().removePhotos(
                        widget.albumId,
                        [p.photoId],
                      );
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
                      refreshSelection();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final albumProvider = context.watch<AlbumProvider>();
    final album = albumProvider.albums.firstWhere(
      (a) => a.albumId == widget.albumId,
      orElse: () => const AlbumItem(
        albumId: -1,
        title: '',
        description: '',
        coverPhotoUrl: null,
        photoCount: 0,
        createdAt: '',
        photoIdList: [],
      ),
    );
    if (album.albumId == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AlbumProvider>().loadDetail(widget.albumId);
        }
      });
    }
    // 앨범은 있으나 상세(사진 목록)가 비어 있으면 상세 재요청
    final shouldFetchDetail = album.albumId != -1 && album.photoIdList.isEmpty;
    if (shouldFetchDetail) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AlbumProvider>().loadDetail(widget.albumId);
        }
      });
    }
    final photos = context.watch<PhotoProvider>().items.where(
      (p) => album.photoIdList.contains(p.photoId),
    );
    final selected = <int>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(album.title.isEmpty ? '앨범' : album.title),
        actions: [
          IconButton(
            onPressed: _working ? null : _addPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: '사진 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          if (album.coverPhotoUrl != null)
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Image.network(
                album.coverPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFFE0E0E0)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    album.description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                Text(
                  '총 ${album.photoCount}장',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // 태그 요약 영역 (모킹 기준)
          FutureBuilder<Map<String, dynamic>>(
            future: AlbumApi.getAlbum(widget.albumId),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final data = snap.data!;
              final List tags = (data['tagList'] as List? ?? []);
              if (tags.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tags
                      .map(
                        (e) => Chip(
                          label: Text('#$e'),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList()
                      .cast<Widget>(),
                ),
              );
            },
          ),
          Expanded(
            child: shouldFetchDetail
                ? const Center(child: CircularProgressIndicator())
                : StatefulBuilder(
                    builder: (context, setInner) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemCount: photos.length,
                        itemBuilder: (_, i) {
                          final p = photos.elementAt(i);
                          final isSel = selected.contains(p.photoId);
                          return GestureDetector(
                            onDoubleTap: () async {
                              try {
                                await AlbumApi.setCoverPhoto(
                                  albumId: widget.albumId,
                                  photoId: p.photoId,
                                );
                                if (!mounted) return;
                                context.read<AlbumProvider>().updateCoverUrl(
                                  widget.albumId,
                                  p.imageUrl,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('대표사진이 설정되었습니다.'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('대표 설정 실패: $e')),
                                );
                              }
                            },
                            onLongPress: () {
                              setInner(() {
                                if (isSel) {
                                  selected.remove(p.photoId);
                                } else {
                                  selected.add(p.photoId);
                                }
                              });
                            },
                            onTap: () {
                              if (selected.isEmpty) {
                                // 전체화면 뷰어로 진입 (사진탭과 동일)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PhotoViewerScreen(
                                      photoId: p.photoId,
                                      imageUrl: p.imageUrl,
                                    ),
                                  ),
                                );
                              } else {
                                setInner(() {
                                  if (isSel) {
                                    selected.remove(p.photoId);
                                  } else {
                                    selected.add(p.photoId);
                                  }
                                });
                              }
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  p.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                ),
                                if (isSel)
                                  Container(
                                    color: Colors.blue.withOpacity(0.25),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _working
                ? null
                : () async {
                    // 선택된 사진 삭제
                    final toRemove = selected.toList();
                    await _removeSelected(toRemove);
                  },
            icon: const Icon(Icons.delete_outline),
            label: const Text('선택 사진 삭제'),
          ),
        ),
      ),
    );
  }
}
