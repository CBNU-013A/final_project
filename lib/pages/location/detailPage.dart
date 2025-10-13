// pages/location/DetailPage.dart
import 'dart:async';
import 'dart:io';
import 'package:pik/services/location_service.dart';
import 'package:pik/widgets/like_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pik/main.dart';
import 'package:pik/services/like_service.dart';
import 'package:pik/styles/styles.dart';
import 'package:pik/widgets/BottomNavi.dart';
import 'package:pik/widgets/detail/AnalysisTab.dart';
import 'package:pik/widgets/detail/InfoTab.dart';
import 'package:pik/widgets/detail/ReviewTab.dart';
import 'package:pik/widgets/detail/summaryTab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseUrl = Platform.isAndroid
    ? 'http://${dotenv.env['BASE_URL']}:8001'
    : 'http://localhost:8001';

class DetailPage extends StatefulWidget {
  final String placeId;
  final String placeName;

  const DetailPage({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  late SharedPreferences prefs;
  String token = ''; //토큰 저장
  String userId = ''; //유저아이디 저장
  String userName = ''; //유저네임 저장

  final likeService = LikeService();
  final _locationSrvice = LocationService();

  Map<String, dynamic> placeData = {};

  bool _isLoading = true;
  bool _isPlaceFound = false;
  Map<String, dynamic>? _matchedPlace;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    loadPlace();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    userName = prefs.getString('userName') ?? '';
    token = prefs.getString('token') ?? '';
  }

  void loadPlace() async {
    try {
      // placeId가 유효한지 확인
      if (widget.placeId.isEmpty || widget.placeId == 'null') {
        setState(() {
          _isLoading = false;
          _isPlaceFound = false;
        });
        return;
      }

      final data = await _locationSrvice.fetchLocation(widget.placeId);

      if (data.isNotEmpty) {
        placeData = data;
        setState(() {
          _matchedPlace = placeData;
          _isPlaceFound = true;
          _isLoading = false;
          _tabController = TabController(length: 4, vsync: this);
        });
      } else {
        setState(() {
          _isPlaceFound = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ 장소 불러오기 실패: $e");
      setState(() {
        _isPlaceFound = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.placeName} ',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.grey),
        ),
      );
    }

    if (!_isPlaceFound) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.placeName} ',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text(
            '해당 장소에 대한 데이터를 찾을 수 없습니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              // 🔥 AppBar도 NestedScrollView 안으로
              expandedHeight: 60,
              title: Text(
                '${widget.placeName} ',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              floating: true,
              pinned: true,
              backgroundColor: AppColors.lightGreen,
              actions: [
                LikeButton(
                  userId: userId,
                  placeId: widget.placeId,
                  token: token,
                ),
              ],
            ),
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxStyles.backgroundBox(),
                  child: Column(
                    children: [
                      ImageSection(context: context, place: _matchedPlace!),
                      KeywordsSection(place: _matchedPlace!),
                      InfoSection(data: _matchedPlace!),
                    ],
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                  child: PreferredSize(
                preferredSize: const Size.fromHeight(48.0), // ✅ 정확한 높이 지정
                child: Container(
                  color: AppColors.lightWhite,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.black,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: '요약'),
                      Tab(text: '분석'),
                      Tab(text: '리뷰'),
                      Tab(text: '정보'),
                    ],
                    onTap: (index) {
                      setState(() {
                        _tabController.index =
                            index; // Index 변경: 1, 2, 3, 4로 설정
                      });
                    },
                  ),
                ),
              )),
            ),
          ];
        },
        body: _matchedPlace == null
            ? const Center(child: CircularProgressIndicator(color: Colors.grey))
            : TabBarView(
                controller: _tabController,
                children: [
                  SummaryTab(data: {
                    'title': _matchedPlace!['title'],
                    'overview': _matchedPlace!['overview'],
                    'llmoverview': _matchedPlace!['llmoverview'],
                    '_id': _matchedPlace!['_id'],
                    'onTabChange': () {
                      setState(() {
                        _tabController.index = 1; // 분석 탭으로 이동
                      });
                    },
                    'onGoReview': () {
                      setState(() {
                        _tabController.index = 2; // 리뷰 탭으로 이동
                      });
                    }
                  }),
                  AnalysisTab(data: _matchedPlace!),
                  ReviewsTab(
                    data: _matchedPlace!,
                  ),
                  InfoTab(data: _matchedPlace!)
                ],
              ),
      ),
      bottomNavigationBar: const BottomNavi(),
    );
  }
}

class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    String extractHref(String htmlString) {
      final match = RegExp(r'href="([^"]+)"').firstMatch(htmlString);
      return match != null ? match.group(1)! : '';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.start,
              spacing: 1,
              runSpacing: 0,
              children: [
                TextButton.icon(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.all(6.0)),
                    minimumSize: MaterialStateProperty.all(Size.zero),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: data['addr1'] ?? ""));
                    HapticFeedback.mediumImpact();
                    rootScaffoldMessengerKey.currentState!.showSnackBar(
                      SnackBarStyles.info("복사 완료"),
                    );
                  },
                  label: const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: AppColors.mustedBlush,
                  ),
                ),
                Text(
                  '${data['addr1'] ?? '주소 정보 없음'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              spacing: 1,
              runSpacing: 0,
              children: [
                TextButton.icon(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.all(6.0)),
                    minimumSize: MaterialStateProperty.all(Size.zero),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    rootScaffoldMessengerKey.currentState!.showSnackBar(
                      SnackBarStyles.info("전화 연결 기능 만들어야함"),
                    );
                  },
                  label: const Icon(
                    Icons.phone,
                    size: 20,
                    color: AppColors.mustedBlush,
                  ),
                ),
                Text(
                  '${data['tell'] ?? '번호 정보 없음'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.start,
              spacing: 1,
              runSpacing: 0,
              children: [
                TextButton.icon(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.all(6.0)),
                    minimumSize: MaterialStateProperty.all(Size.zero),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {},
                  label: const Icon(
                    Icons.link,
                    size: 20,
                    color: AppColors.mustedBlush,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final rawHtml = data['homepage'] ?? '';
                    final extractedUrl = extractHref(rawHtml);
                    if (extractedUrl.isEmpty) {
                      debugPrint("❌ URL이 비어 있음");
                      return;
                    }
                    Uri? uri;
                    try {
                      uri = Uri.parse(extractedUrl);
                      if (uri.host.isEmpty || !uri.hasScheme) {
                        debugPrint("❌ URI 호스트 또는 스킴 없음: $extractedUrl");
                        return;
                      }
                    } catch (e) {
                      debugPrint("❌ URI 파싱 오류: $e");
                      return;
                    }
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        debugPrint('❌ 링크 실행 실패: $extractedUrl');
                      }
                    } catch (e) {
                      debugPrint('❗ URL 파싱 오류: $e');
                    }
                  },
                  child: const Text(
                    '홈페이지로 이동',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class KeywordsSection extends StatelessWidget {
  const KeywordsSection({super.key, required this.place});

  final Map<String, dynamic> place;

  List<String> _extractTopKeywords(Map<String, dynamic> place) {
    // 1) Try structured 'keywords' from API: expect a list of maps with {name, sentiment:{total}}
    final raw = place['keywords'];
    if (raw is List) {
      try {
        final items = raw
            .whereType<Map>()
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();

        // sort by total sentiment score desc if present
        items.sort((a, b) {
          final at = (a['sentiment'] is Map && (a['sentiment']['total'] is num))
              ? (a['sentiment']['total'] as num).toDouble()
              : 0.0;
          final bt = (b['sentiment'] is Map && (b['sentiment']['total'] is num))
              ? (b['sentiment']['total'] as num).toDouble()
              : 0.0;
          return bt.compareTo(at);
        });

        final names = items
            .map((e) => (e['name'] ?? '').toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          return names.take(3).toList();
        }
      } catch (_) {}
    }

    // 2) Fallback: for known place "보살사"
    final title = (place['title'] ?? '').toString();
    if (title.contains('보살사')) {
      return const ['문화역사', '관람', '가족'];
    }

    // 3) As a last resort, try to infer a couple of general tags
    if ((place['overview'] ?? '').toString().isNotEmpty) {
      return const ['자연', '역사', '휴식'];
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final tags = _extractTopKeywords(place);
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: SizedBox(
        height: 40, // ✅ 높이를 살짝 키움
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: tags
                .map(
                  (t) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.lighterGreen.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.mainGreen.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tag,
                            size: 16, color: AppColors.deepGrean),
                        const SizedBox(width: 6),
                        Text(
                          t,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.deepGrean,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class ImageSection extends StatefulWidget {
  const ImageSection({
    super.key,
    required this.context,
    required this.place,
  });

  final BuildContext context;
  final Map<String, dynamic> place;

  @override
  State<ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<ImageSection> {
  @override
  Widget build(BuildContext context) {
    String imageUrl = widget.place['firstimage'] ?? '';
    final double imageHeight = 250.0;
    final double imageWidth = MediaQuery.of(context).size.width;

    Widget noImagePlaceholder() {
      return SizedBox(
        height: imageHeight,
        width: imageWidth,
        child: Container(
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Text(
            'No Image',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (imageUrl.isEmpty) {
      return noImagePlaceholder();
    }

    return SizedBox(
      height: imageHeight,
      width: imageWidth,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: imageHeight,
        width: imageWidth,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
              child: CircularProgressIndicator(color: Colors.grey));
        },
        errorBuilder: (context, error, stackTrace) {
          return noImagePlaceholder();
        },
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate({required this.child});

  final Widget child;

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }

  @override
  double get minExtent => child is PreferredSizeWidget
      ? (child as PreferredSizeWidget).preferredSize.height
      : 50;
  @override
  double get maxExtent => child is PreferredSizeWidget
      ? (child as PreferredSizeWidget).preferredSize.height
      : 50;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: child,
    );
  }
}
