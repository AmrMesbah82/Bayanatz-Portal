// ******************* FILE INFO *******************
// Part of: services_main.dart
// Contains: _buildTabBar, _mainTab, _digitalJourneyTab, _readMoreTab,
//           _blogCardGrid

part of '../../pages/services_main/services_main.dart';

extension _ServicesMainTabs on _ServicesMainPageMasterState {
  // ── Tab bar ──────────────────────────────────────────────────────────────────
  // BUG-155: shared sub-tab row (same look on every CMS tab).
  Widget _buildTabBar() {
    return CmsSubTabs(
      labels: _statusLabels,
      activeIndex: _statusIndex,
      onTap: (i) => setState(() => _statusIndex = i),
    );
  }

  // ── Tab 0 — Main ─────────────────────────────────────────────────────────────
  Widget _mainTab(ServicePageModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lastUpdatedRow(
          lastUpdated: model.lastUpdatedAt,
          onEdit: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ServiceCmsCubit>(),
                child: ServicesMainEditPage(model: model),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _accordion(
          key:   'headings',
          title: 'Headings',
          children: [

            Row(children: [
              Expanded(child: _readField('Title',
                  model.title.en.isEmpty ? 'Text Here' : model.title.en)),
              SizedBox(width: 16.w),
              Expanded(child: _readFieldRtl('العنوان', model.title.ar)),
            ]),
            _readField('Description',
                model.shortDescription.en.isEmpty
                    ? 'Text Here' : model.shortDescription.en,
                height: 100),
            _readFieldRtl('وصف', model.shortDescription.ar, height: 100),
          ],
        ),
      ],
    );
  }

  // ── Tab 1 — Digital Journey ───────────────────────────────────────────────────
  Widget _digitalJourneyTab(ServicePageModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lastUpdatedRow(
          lastUpdated: model.lastUpdatedAt,
          onEdit: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ServiceCmsCubit>(),
                child: ServicesDigitalJourneyEditPage(model: model),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _accordion(
          key: 'digitalJourney',
          title: 'Digital Journey',
          children: [
            Row(children: [
              Expanded(
                child: _readField('Section Title',
                  model.journeyTitle.en.isEmpty ? 'Text Here' : FormatHelper.capitalize(model.journeyTitle.en)),
              ),
              SizedBox(width: 16.w),
              Expanded(child: _readFieldRtl('عنوان القسم', FormatHelper.capitalize(model.journeyTitle.ar))),
            ]),
            SizedBox(height: 14.h),
            if (model.journeyItems.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Text('No journey items yet.',
                      style: StyleText.fontSize13Weight400
                          .copyWith(color: AppColors.secondaryText)),
                ),
              )
            else
              _journeyGrid(model.journeyItems),
          ],
        ),
      ],
    );
  }

  // ── Tab 2 — Important Reads ───────────────────────────────────────────────────
  Widget _readMoreTab() {
    return BlocBuilder<BlogCubit, BlogState>(
      builder: (context, blogState) {
        if (blogState is BlogLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircleProgress(),
            ),
          );
        }

        final List<BlogPostModel> allPosts = switch (blogState) {
          BlogLoaded(:final posts) => posts,
          _ => <BlogPostModel>[],
        };

        // BUG-92: removed reads live only in "Removed" (same rule as the
        // Job Listing "All" tab, BUG-269).
        final livePosts = allPosts.where((p) => p.status != 'removed').toList();
        int _count(_PostStatus s) => s == _PostStatus.all
            ? livePosts.length
            : allPosts.where((p) => p.status == s.statusKey).length;

        List<BlogPostModel> filtered = _activeFilter == _PostStatus.all
            ? livePosts
            : allPosts.where((p) => p.status == _activeFilter.statusKey).toList();

        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((p) =>
              p.question.en.toLowerCase().contains(_searchQuery) ||
              p.question.ar.toLowerCase().contains(_searchQuery) ||
              p.shortDescription.en.toLowerCase().contains(_searchQuery))
              .toList();
        }

        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search + action buttons ──────────────────────────────────
              Row(children: [
                Expanded(
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(6.r)),
                    child: Row(children: [
                      SizedBox(width: 10.w),
                      CustomSvg(assetPath: "assets/searchIcon.svg",
                          width: 20.w, height: 20.h, fit: BoxFit.fill),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _searchCtrl,
                          valueStyle: StyleText.fontSize13Weight400
                              .copyWith(color: AppColors.text),
                          hint: 'Search',
                          hintStyle: StyleText.fontSize13Weight400
                              .copyWith(color: AppColors.secondaryText),
                          fillColor: AppColors.card,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ]),
                  ),
                ),
                SizedBox(width: 12.w),
                // 'Time Frame' removed — it did nothing (onTap: () {}).
                _actionBtn(label: 'Add New Read', onTap: _navigateToCreate, outlined: false),
              ]),
              SizedBox(height: 16.h),

              // ── Filter chips ─────────────────────────────────────────────
              Row(
                children: _PostStatus.values.map((s) {
                  final isActive = _activeFilter == s;
                  final int cnt  = _count(s);
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeFilter = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: isActive ? ColorPick.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (s != _PostStatus.all) ...[
                            Container(
                              width: 18.w, height: 18.w,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : ColorPick.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('$cnt',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    )),
                              ),
                            ),
                            SizedBox(width: 6.w),
                          ],
                          Text(s.label,
                              style: StyleText.fontSize13Weight500.copyWith(
                                  color: isActive ? Colors.white : AppColors.text)),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),

              // ── Cards grid ───────────────────────────────────────────────
              filtered.isEmpty
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: SvgPicture.asset(
                    'assets/images/null.svg',
                    width: 200.w,
                    height: 200.h,
                  ),
                ),
              )
                  : _blogCardGrid(filtered),
            ],
          ),
        );
      },
    );
  }

  // ── 2-column blog card grid ───────────────────────────────────────────────────
  // Was 3 across. At a third of the width each card was too narrow for its own
  // content: the title and description had to be clipped to two lines to sit
  // beside the image. Two across gives each card enough room for the text to
  // run its full height — see the two-column layout in _BlogCard.
  static const int _kBlogCardsPerRow = 2;

  Widget _blogCardGrid(List<BlogPostModel> posts) {
    final List<List<BlogPostModel>> rows = [];
    for (int i = 0; i < posts.length; i += _kBlogCardsPerRow) {
      rows.add(posts.skip(i).take(_kBlogCardsPerRow).toList());
    }
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...row.map((post) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: _BlogCard(
                    post:     post,
                    onEdit:   () => _navigateToEdit(post),
                    onDelete: () => _confirmDelete(post),
                  ),
                ),
              )),
              // Pad the last row so a lone card keeps its column width instead
              // of stretching across the whole grid.
              ...List.generate(_kBlogCardsPerRow - row.length,
                  (_) => const Expanded(child: SizedBox())),
            ],
          ),
        );
      }).toList(),
    );
  }
}
