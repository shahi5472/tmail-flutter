import 'dart:async';

import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/sort/comparator.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/core/utc_date.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_comparator.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_comparator_property.dart';
import 'package:model/model.dart';
import 'package:tmail_ui_user/features/base/base_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/model/recent_search.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/state/get_all_recent_search_latest_state.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/state/quick_search_email_state.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_all_recent_search_latest_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/quick_search_email_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/save_recent_search_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/email_receive_time_type.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/quick_search_filter.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/search_email_filter.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/widgets/advanced_search/advanced_search_filter_bottom_sheet.dart';
import 'package:tmail_ui_user/features/thread/domain/constants/thread_constants.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';
import 'package:tmail_ui_user/features/thread/presentation/model/search_state.dart';
import 'package:tmail_ui_user/features/thread/presentation/model/search_status.dart';

class SearchController extends BaseController {
  final QuickSearchEmailInteractor _quickSearchEmailInteractor;
  final SaveRecentSearchInteractor _saveRecentSearchInteractor;
  final GetAllRecentSearchLatestInteractor _getAllRecentSearchLatestInteractor;

  final ResponsiveUtils _responsiveUtils = Get.find<ResponsiveUtils>();

  final searchInputController = TextEditingController();
  final searchEmailFilter = SearchEmailFilter.initial().obs;
  final searchState = SearchState.initial().obs;
  final isAdvancedSearchViewOpen = false.obs;
  final emailReceiveTimeType = Rxn<EmailReceiveTimeType>();
  final simpleSearchIsActivated = RxBool(false);
  final advancedSearchIsActivated = RxBool(false);
  final autoFocus = RxBool(true);

  SearchQuery? get searchQuery => searchEmailFilter.value.text;

  FocusNode searchFocus = FocusNode();

  SearchController(
    this._quickSearchEmailInteractor,
    this._saveRecentSearchInteractor,
    this._getAllRecentSearchLatestInteractor,
  );

  @override
  void onInit() {
    _registerSearchFocusListener();
    super.onInit();
  }

  selectOpenAdvanceSearch() {
    isAdvancedSearchViewOpen.toggle();
  }

  void clearSearchFilter() {
    searchEmailFilter.value = SearchEmailFilter.initial();
  }

  void selectQuickSearchFilter({
    required QuickSearchFilter quickSearchFilter,
    required UserProfile userProfile,
    bool fromSuggestionBox = false,
  }) {
    final quickSearchFilterSelected = checkQuickSearchFilterSelected(
      userProfile: userProfile,
      quickSearchFilter: quickSearchFilter,
      fromSuggestionBox: fromSuggestionBox,
    );

    switch (quickSearchFilter) {
      case QuickSearchFilter.hasAttachment:
        updateFilterEmail(hasAttachment: !quickSearchFilterSelected);
        return;
      case QuickSearchFilter.last7Days:
        if (quickSearchFilterSelected) {
          setEmailReceiveTimeType(null);
          updateFilterEmail(emailReceiveTimeType: EmailReceiveTimeType.allTime);
        } else {
          setEmailReceiveTimeType(EmailReceiveTimeType.last7Days);
          updateFilterEmail(emailReceiveTimeType: EmailReceiveTimeType.last7Days);
        }
        return;
      case QuickSearchFilter.fromMe:
        quickSearchFilterSelected
            ? searchEmailFilter.value.from.removeWhere((e) => e == userProfile.email)
            : searchEmailFilter.value.from.add(userProfile.email);
        updateFilterEmail(from: searchEmailFilter.value.from);
        return;
    }
  }

  Future<List<PresentationEmail>> quickSearchEmails({required AccountId accountId}) async {
    return await _quickSearchEmailInteractor
        .execute(accountId,
            limit: UnsignedInt(5),
            sort: <Comparator>{}..add(
                EmailComparator(EmailComparatorProperty.receivedAt)
                  ..setIsAscending(false)),
            filter: searchEmailFilter.value.mappingToEmailFilterCondition(),
            properties: ThreadConstants.propertiesQuickSearch)
        .then((result) => result.fold(
            (failure) => <PresentationEmail>[],
            (success) => success is QuickSearchEmailSuccess
                ? success.emailList
                : <PresentationEmail>[]));
  }

  void updateFilterEmail({
    Set<String>? from,
    Set<String>? to,
    SearchQuery? text,
    Option<String>? subjectOption,
    Set<String>? notKeyword,
    PresentationMailbox? mailbox,
    EmailReceiveTimeType? emailReceiveTimeType,
    bool? hasAttachment,
    UTCDate? before,
    UTCDate? startDate,
    UTCDate? endDate,
  }) {
    searchEmailFilter.value = searchEmailFilter.value.copyWith(
      from: from,
      to: to,
      text: text,
      subjectOption: subjectOption,
      notKeyword: notKeyword,
      mailbox: mailbox,
      emailReceiveTimeType: emailReceiveTimeType,
      hasAttachment: hasAttachment,
      before: before,
      startDate: startDate,
      endDate: endDate,
    );
    searchEmailFilter.refresh();
  }

  void _registerSearchFocusListener() {
    searchFocus.addListener(() {
      final hasFocus = searchFocus.hasFocus;
      final query = searchEmailFilter.value.text?.value;
      log('SearchController::_registerSearchFocusListener(): hasFocus: $hasFocus | query: $query');
      if (!hasFocus && (query == null || query.isEmpty) && advancedSearchIsActivated.isFalse) {
        updateFilterEmail(text: SearchQuery.initial());
        searchInputController.clear();
        clearSearchFilter();
        searchFocus.unfocus();
      }
    });
  }

  bool isSearchActive() =>
      searchState.value.searchStatus == SearchStatus.ACTIVE;

  bool get isSearchEmailRunning => simpleSearchIsActivated.isTrue || advancedSearchIsActivated.isTrue;

  void enableSearch() {
    searchState.value = searchState.value.enableSearchState();
  }

  void disableSimpleSearch() {
    updateFilterEmail(text: SearchQuery.initial());
    _clearAllTextInputSimpleSearch();
    hideSimpleSearchFormView();
  }

  void clearTextSearch() {
    updateFilterEmail(text: SearchQuery.initial());
    searchInputController.clear();
    searchFocus.requestFocus();
  }

  void onChangeTextSearch(String value) {
    updateFilterEmail(text: SearchQuery(value));
  }

  void updateTextSearch(String value) {
    searchInputController.text = value;
  }

  bool checkQuickSearchFilterSelected({
    required QuickSearchFilter quickSearchFilter,
    required UserProfile userProfile,
    bool fromSuggestionBox = false,
  }) {
    switch (quickSearchFilter) {
      case QuickSearchFilter.hasAttachment:
        return searchEmailFilter.value.hasAttachment == true;
      case QuickSearchFilter.last7Days:
        if (emailReceiveTimeType.value != null) {
          return true;
        }
        return searchEmailFilter.value.emailReceiveTimeType == EmailReceiveTimeType.last7Days;
      case QuickSearchFilter.fromMe:
        return searchEmailFilter.value.from.contains( userProfile.email) && searchEmailFilter.value.from.length == 1;
    }
  }

  void saveRecentSearch(RecentSearch recentSearch) {
    consumeState(_saveRecentSearchInteractor.execute(recentSearch));
  }

  Future<List<RecentSearch>> getAllRecentSearchAction(String pattern) async {
    return await _getAllRecentSearchLatestInteractor
        .execute(pattern: pattern)
        .then((result) => result.fold(
            (failure) => <RecentSearch>[],
            (success) => success is GetAllRecentSearchLatestSuccess
                ? success.listRecentSearch
                : <RecentSearch>[]));
  }

  void setEmailReceiveTimeType(EmailReceiveTimeType? receiveTimeType) {
    emailReceiveTimeType.value = receiveTimeType;
  }

  showAdvancedFilterView(BuildContext context) async {
    selectOpenAdvanceSearch();
    if (_responsiveUtils.isMobile(context)) {
      await showAdvancedSearchFilterBottomSheet(context);
      selectOpenAdvanceSearch();
    }
  }

  void activateSimpleSearch() {
    simpleSearchIsActivated.value = true;
  }

  void deactivateSimpleSearch() {
    simpleSearchIsActivated.value = false;
  }

  void activateAdvancedSearch() {
    advancedSearchIsActivated.value = true;
  }

  void deactivateAdvancedSearch() {
    advancedSearchIsActivated.value = false;
  }

  void hideAdvancedSearchFormView() {
    isAdvancedSearchViewOpen.value = false;
  }

  void hideSimpleSearchFormView() {
    searchState.value = searchState.value.disableSearchState();
  }

  void _clearAllTextInputSimpleSearch() {
    searchInputController.clear();
    searchFocus.unfocus();
    emailReceiveTimeType.value = null;
  }

  void disableAllSearchEmail() {
    _clearAllTextInputSimpleSearch();
    deactivateSimpleSearch();
    hideSimpleSearchFormView();

    clearSearchFilter();
    deactivateAdvancedSearch();
    hideAdvancedSearchFormView();
  }

  @override
  void onDone() {}

  @override
  void onClose() {
    searchInputController.dispose();
    searchFocus.dispose();
    super.onClose();
  }
}
