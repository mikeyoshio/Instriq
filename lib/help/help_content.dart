import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/help_article.dart';

const String _imagesPath = 'assets/help/images';

/// Contingut de la wiki d'ajuda, agrupat per categoria. Es reconstrueix a
/// cada `build()` (barat: només `String`s i `const` widgets) perquè els
/// textos surten de `AppLocalizations`, que no es pot capturar en una
/// `const` de nivell superior.
List<HelpCategory> buildHelpCategories(AppLocalizations l10n) {
  return [
    HelpCategory(
      title: l10n.helpCategoryGettingStarted,
      articles: [
        HelpArticle(
          id: 'onboarding',
          icon: Icons.waving_hand_outlined,
          title: l10n.helpArticleOnboardingTitle,
          intro: l10n.helpArticleOnboardingIntro,
          steps: [
            HelpStep(text: l10n.helpArticleOnboardingStep1, image: '$_imagesPath/onboarding_welcome.png'),
            HelpStep(text: l10n.helpArticleOnboardingStep2),
          ],
        ),
        HelpArticle(
          id: 'change_language',
          icon: Icons.language,
          title: l10n.helpArticleLanguageTitle,
          intro: l10n.helpArticleLanguageIntro,
          steps: [
            HelpStep(text: l10n.helpArticleLanguageStep1, image: '$_imagesPath/profile_guest.png'),
            HelpStep(text: l10n.helpArticleLanguageStep2, image: '$_imagesPath/language_dialog.png'),
          ],
        ),
      ],
    ),
    HelpCategory(
      title: l10n.helpCategoryCatalog,
      articles: [
        HelpArticle(
          id: 'catalog_search',
          icon: Icons.search,
          title: l10n.helpArticleCatalogSearchTitle,
          intro: l10n.helpArticleCatalogSearchIntro,
          steps: [
            HelpStep(text: l10n.helpArticleCatalogSearchStep1, image: '$_imagesPath/catalog_filters.png'),
            HelpStep(text: l10n.helpArticleCatalogSearchStep2),
          ],
        ),
        HelpArticle(
          id: 'instrument_detail',
          icon: Icons.info_outline,
          title: l10n.helpArticleInstrumentDetailTitle,
          intro: l10n.helpArticleInstrumentDetailIntro,
          steps: [
            HelpStep(text: l10n.helpArticleInstrumentDetailStep1, image: '$_imagesPath/instrument_detail.png'),
            HelpStep(text: l10n.helpArticleInstrumentDetailStep2),
          ],
        ),
        HelpArticle(
          id: 'sutures',
          icon: Icons.linear_scale,
          title: l10n.helpArticleSuturesTitle,
          intro: l10n.helpArticleSuturesIntro,
          steps: [
            HelpStep(text: l10n.helpArticleSuturesStep1, image: '$_imagesPath/sutures_list.png'),
            HelpStep(text: l10n.helpArticleSuturesStep2, image: '$_imagesPath/suture_detail.png'),
          ],
        ),
      ],
    ),
    HelpCategory(
      title: l10n.helpCategoryPublicLibrary,
      articles: [
        HelpArticle(
          id: 'public_library',
          icon: Icons.public,
          title: l10n.helpArticlePublicLibraryTitle,
          intro: l10n.helpArticlePublicLibraryIntro,
          steps: [
            HelpStep(text: l10n.helpArticlePublicLibraryStep1, image: '$_imagesPath/library_hub.png'),
            HelpStep(text: l10n.helpArticlePublicLibraryStep2, image: '$_imagesPath/public_library_empty.png'),
          ],
        ),
      ],
    ),
    HelpCategory(
      title: l10n.helpCategoryOrganization,
      articles: [
        HelpArticle(
          id: 'workspaces',
          icon: Icons.hub_outlined,
          title: l10n.helpArticleWorkspacesTitle,
          intro: l10n.helpArticleWorkspacesIntro,
          steps: [
            HelpStep(text: l10n.helpArticleWorkspacesStep1, image: '$_imagesPath/workspace_list.png'),
            HelpStep(text: l10n.helpArticleWorkspacesStep2, image: '$_imagesPath/workspace_detail.png'),
          ],
        ),
      ],
    ),
    HelpCategory(
      title: l10n.helpCategoryAccount,
      articles: [
        HelpArticle(
          id: 'account',
          icon: Icons.account_circle_outlined,
          title: l10n.helpArticleAccountTitle,
          intro: l10n.helpArticleAccountIntro,
          steps: [
            HelpStep(text: l10n.helpArticleAccountStep1, image: '$_imagesPath/profile_authenticated.png'),
            HelpStep(text: l10n.helpArticleAccountStep2),
          ],
        ),
      ],
    ),
    HelpCategory(
      title: l10n.helpCategoryLearning,
      articles: [
        HelpArticle(
          id: 'learn_modes',
          icon: Icons.school_outlined,
          title: l10n.helpArticleLearnModesTitle,
          intro: l10n.helpArticleLearnModesIntro,
          steps: [
            HelpStep(text: l10n.helpArticleLearnModesStep1, image: '$_imagesPath/learn_hub.png'),
            HelpStep(text: l10n.helpArticleLearnModesStep2, image: '$_imagesPath/flashcard_front.png'),
            HelpStep(text: l10n.helpArticleLearnModesStep3, image: '$_imagesPath/quiz_answered.png'),
          ],
        ),
        HelpArticle(
          id: 'my_progress',
          icon: Icons.insights_outlined,
          title: l10n.helpArticleMyProgressTitle,
          intro: l10n.helpArticleMyProgressIntro,
          steps: [
            HelpStep(text: l10n.helpArticleMyProgressStep1, image: '$_imagesPath/my_progress.png'),
          ],
        ),
      ],
    ),
  ];
}
