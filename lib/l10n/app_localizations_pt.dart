// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'PopMatch';

  @override
  String get okButton => 'OK';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get backButton => 'Voltar';

  @override
  String get nextButton => 'Próximo';

  @override
  String get saveButton => 'Salvar';

  @override
  String get retryButton => 'Tentar novamente';

  @override
  String get viewAll => 'Ver tudo';

  @override
  String get loadingText => 'Carregando...';

  @override
  String get anyOption => 'Qualquer';

  @override
  String get navDiscover => 'Descobrir';

  @override
  String get navSearch => 'Pesquisar';

  @override
  String get navWatchlist => 'Minha lista';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get moviesTab => 'FILMES';

  @override
  String get showsTab => 'SÉRIES';

  @override
  String get signInSubtitle => 'Entre para continuar descobrindo filmes';

  @override
  String get emailHint => 'E-mail';

  @override
  String get emailErrorEmpty => 'Por favor, insira seu e-mail';

  @override
  String get emailErrorInvalid => 'Por favor, insira um e-mail válido';

  @override
  String get passwordHint => 'Senha';

  @override
  String get passwordErrorEmpty => 'Por favor, insira sua senha';

  @override
  String get passwordErrorTooShort =>
      'A senha deve ter pelo menos 6 caracteres';

  @override
  String get signInButton => 'Entrar';

  @override
  String get orSeparator => 'OU';

  @override
  String get continueWithGoogleButton => 'Continuar com o Google';

  @override
  String get noAccountPrompt => 'Não tem uma conta? ';

  @override
  String get signUpLinkText => 'Cadastre-se';

  @override
  String get forgotPasswordButton => 'Esqueceu a senha?';

  @override
  String get joinPopMatchTitle => 'JUNTE-SE AO POPMATCH';

  @override
  String get registerSubtitle =>
      'Crie uma conta para começar a descobrir filmes';

  @override
  String get displayNameHint => 'Nome de exibição';

  @override
  String get displayNameErrorEmpty => 'Por favor, insira seu nome de exibição';

  @override
  String get displayNameErrorTooShort =>
      'O nome deve ter pelo menos 2 caracteres';

  @override
  String get confirmPasswordHint => 'Confirmar senha';

  @override
  String get confirmPasswordErrorEmpty => 'Por favor, confirme sua senha';

  @override
  String get confirmPasswordErrorMismatch => 'As senhas não coincidem';

  @override
  String get createAccountButton => 'Criar conta';

  @override
  String get alreadyHaveAccountPrompt => 'Já tem uma conta? ';

  @override
  String get signInLinkText => 'Entrar';

  @override
  String get forgotPasswordTitle => 'ESQUECEU SUA SENHA?';

  @override
  String get checkEmailTitle => 'VERIFIQUE SEU E-MAIL';

  @override
  String get forgotPasswordSubtitle =>
      'Sem problemas! Insira seu e-mail e enviaremos instruções para redefini-la.';

  @override
  String checkEmailSubtitle(String email) {
    return 'Enviamos um link de redefinição para $email';
  }

  @override
  String get sendResetLinkButton => 'Enviar link';

  @override
  String get resetEmailNotReceivedMessage =>
      'Não recebeu o e-mail? Verifique sua pasta de spam ou tente novamente em alguns minutos.';

  @override
  String get resendEmailButton => 'Reenviar e-mail';

  @override
  String get backToLoginButton => 'Voltar ao login';

  @override
  String get rememberPasswordPrompt => 'Lembra sua senha? ';

  @override
  String get verifyEmailTitle => 'Verifique seu e-mail';

  @override
  String get verificationCodeDescription =>
      'Enviamos um código de 6 dígitos para:';

  @override
  String get verifyCodeButton => 'Verificar código';

  @override
  String get resendCodeButton => 'Reenviar código';

  @override
  String get emailVerificationHelper =>
      'Não recebeu o código? Verifique seu spam ou reenvie.';

  @override
  String get incompleteCodeError =>
      'Por favor, insira o código completo de 6 dígitos';

  @override
  String get codeError => 'Por favor, insira um código de 6 dígitos';

  @override
  String get invalidCodeError =>
      'Código de verificação inválido. Tente novamente.';

  @override
  String get emailVerificationSuccess => 'E-mail verificado com sucesso!';

  @override
  String get verificationCodeSentMessage =>
      'Código enviado! Por favor, verifique seu e-mail.';

  @override
  String get verificationCodeFallbackMessage =>
      'O serviço de e-mail está indisponível. Seu código foi gerado no aplicativo.';

  @override
  String get verificationCodeDevMessage =>
      'Código gerado em modo de desenvolvimento. Verifique os logs de depuração.';

  @override
  String get verificationCodeGeneratedMessage =>
      'Código de verificação gerado. Tente novamente se necessário.';

  @override
  String get swipeToMatchTitle => 'DESLIZE PARA COMBINAR';

  @override
  String get swipeToMatchDescription =>
      'Deslize para a direita para curtir, para a esquerda para passar.\nEncontre o filme perfeito para você.';

  @override
  String get aiPoweredPicksTitle => 'Escolhas com IA';

  @override
  String get aiPoweredPicksDescription =>
      'Nossa IA aprende seus gostos para sugerir filmes que você vai amar.';

  @override
  String get curateWatchlistTitle => 'Monte Sua Lista';

  @override
  String get curateWatchlistDescription =>
      'Salve suas combinações e nunca mais se pergunte o que assistir.';

  @override
  String get getStartedButton => 'Começar';

  @override
  String get welcomeTitle => 'BEM-VINDO AO POPMATCH!';

  @override
  String get welcomeSubtitle =>
      'Vamos personalizar sua descoberta de filmes. Escolha o que você ama e encontraremos as melhores combinações.';

  @override
  String get swipeFeature => 'Deslize para descobrir filmes que você vai amar';

  @override
  String get bookmarkFeature => 'Salve na sua lista de watchlist';

  @override
  String get filterFeature => 'Filtre por gêneros e preferências';

  @override
  String get shareFeature => 'Compartilhe com amigos';

  @override
  String get genresTitle => 'QUAIS GÊNCROS VOCÊ AMA?';

  @override
  String get genresSubtitle =>
      'Selecione seus gêneros favoritos para melhores recomendações.';

  @override
  String get platformsTitle => 'ONDE VOCÊ ASSISTE FILMES?';

  @override
  String get platformsSubtitle =>
      'Selecione os serviços de streaming que você tem acesso.';

  @override
  String pageIndicatorOf3(int current) {
    return '$current de 3';
  }

  @override
  String get loadingGenresMessage => 'Carregando gêneros...';

  @override
  String get matchSwipeUpTooltip => 'Deslize para cima — Combinar';

  @override
  String get swipeLiked => 'Curtido';

  @override
  String get swipePassed => 'Passado';

  @override
  String get swipeWatchlisted => 'Na lista';

  @override
  String get swipeSwiped => 'Deslizado';

  @override
  String get undoButton => 'DESFAZER';

  @override
  String get matchItsA => 'É uma';

  @override
  String get matchTitle => 'COMBINAÇÃO!';

  @override
  String get savedToWatchlist => 'Salvo na sua lista';

  @override
  String get viewDetailsButton => 'Ver detalhes';

  @override
  String get addToWatchlistButton => 'Adicionar à lista';

  @override
  String reasonBecauseYouLike(String genre) {
    return 'Porque você curte $genre';
  }

  @override
  String get strategyLikedSimilar => 'Porque você curtiu títulos similares';

  @override
  String get strategyGenreMatch => 'Combina com seus gêneros';

  @override
  String get strategyTrending => 'Em alta agora';

  @override
  String get strategyTopRated => 'Mais bem avaliado';

  @override
  String get strategyPersonalized => 'Escolhido para você';

  @override
  String get strategyCurated => 'Seleção do editor';

  @override
  String get strategyActorDiscovery => 'De um elenco que você gosta';

  @override
  String get strategyDirectorDiscovery => 'De um diretor que você gosta';

  @override
  String get relaxFiltersButton => 'Relaxar filtros';

  @override
  String get refreshButton => 'Atualizar';

  @override
  String get applyButton => 'Aplicar';

  @override
  String get clearAllButton => 'Limpar tudo';

  @override
  String get filtersSectionTitle => 'Filtros';

  @override
  String get moodFilterLabel => 'Humor';

  @override
  String get selectMoodsHint => 'Selecionar humores';

  @override
  String get selectGenresHint => 'Selecionar gêneros';

  @override
  String get platformFilterLabel => 'Plataforma';

  @override
  String get selectPlatformsHint => 'Selecionar plataformas';

  @override
  String get selectMoodsTitle => 'Selecionar humores';

  @override
  String get selectGenresTitle => 'Selecionar gêneros';

  @override
  String get selectPlatformsTitle => 'Selecionar plataformas';

  @override
  String get nothingHereLabel => 'Nada aqui';

  @override
  String get noMoviesFoundSwipe => 'Nenhum filme encontrado';

  @override
  String get noShowsFoundSwipe => 'Nenhuma série encontrada';

  @override
  String get tryRefreshingMovies => 'Tente atualizar para carregar mais filmes';

  @override
  String get tryRefreshingShows => 'Tente atualizar para carregar mais séries';

  @override
  String get checkBackLaterNewReleases =>
      'Volte mais tarde para novos lançamentos';

  @override
  String get allCaughtUpLabel => 'Você já viu tudo';

  @override
  String get searchTitle => 'Pesquisar';

  @override
  String get searchHintMoviesShows => 'Pesquise filmes e séries...';

  @override
  String get searchMoviesAndShows => 'Pesquise filmes e séries';

  @override
  String get startTypingFindTitles =>
      'Comece a digitar para encontrar títulos instantaneamente';

  @override
  String addedToLikedMovies(String title) {
    return '$title adicionado aos seus filmes curtidos!';
  }

  @override
  String skippedMovie(String title) {
    return 'Pulou $title';
  }

  @override
  String get smartFiltersTitle => 'Filtros inteligentes';

  @override
  String get genresFilterLabel => 'Gêneros';

  @override
  String get yearRangeFilterLabel => 'Intervalo de ano';

  @override
  String get fromLabel => 'De';

  @override
  String get toLabel => 'Até';

  @override
  String get applyFiltersButton => 'Aplicar filtros';

  @override
  String noMoviesFoundType(String type) {
    return 'Nenhum filme de tipo $type encontrado';
  }

  @override
  String get tryAdjustingPreferences =>
      'Tente ajustar suas preferências ou filtros';

  @override
  String get errorLoadingRecommendations => 'Erro ao carregar recomendações';

  @override
  String get searchHint => 'Pesquise filmes, atores ou gêneros...';

  @override
  String get filtersButton => 'Filtros';

  @override
  String get searchButton => 'Pesquisar';

  @override
  String get genreLabel => 'Gênero';

  @override
  String get allGenresOption => 'Todos os gêneros';

  @override
  String get yearLabel => 'Ano';

  @override
  String get allYearsOption => 'Todos os anos';

  @override
  String get sortByLabel => 'Ordenar por';

  @override
  String get relevanceOption => 'Relevância';

  @override
  String get ratingOption => 'Avaliação';

  @override
  String get yearOption => 'Ano';

  @override
  String get titleOption => 'Título';

  @override
  String get showOnlyAvailableCheckbox =>
      'Mostrar apenas disponível em streaming';

  @override
  String get streamingPlatformsLabel => 'Plataformas de streaming';

  @override
  String get recentSearchesTitle => 'Pesquisas recentes';

  @override
  String get noMoviesFound => 'Nenhum filme encontrado';

  @override
  String get tryAdjustingSearchTerms =>
      'Tente ajustar os termos de pesquisa ou filtros';

  @override
  String get searchErrorTitle => 'Erro de pesquisa';

  @override
  String get overviewTab => 'Visão geral';

  @override
  String get seasonsEpisodesTab => 'Temporadas e episódios';

  @override
  String snackbarRemovedFromWatchlist(String title) {
    return '$title removido da lista';
  }

  @override
  String snackbarAddedToWatchlist(String title) {
    return '$title adicionado à lista';
  }

  @override
  String get watchlistTitle => 'MINHA LISTA';

  @override
  String get watchlistEmpty => 'Sua lista está vazia';

  @override
  String get startSwipingAddWatchlist =>
      'Comece a deslizar para adicionar filmes e séries à sua lista!';

  @override
  String removedFromWatchlist(String title) {
    return '$title removido da lista';
  }

  @override
  String movedToFavorites(String title) {
    return '$title movido para Favoritos';
  }

  @override
  String markedAsDisliked(String title) {
    return '$title marcado como não curtido';
  }

  @override
  String get likedAction => 'Curtido';

  @override
  String get likedActionSubtitle => 'Adicionar a Favoritos e remover da lista';

  @override
  String get dislikedAction => 'Não curtido';

  @override
  String get dislikedActionSubtitle =>
      'Marcar como não curtido e remover da lista';

  @override
  String get removeAction => 'Remover';

  @override
  String get removeActionSubtitle => 'Remover apenas da lista';

  @override
  String get noMoviesInWatchlist => 'Nenhum filme na lista';

  @override
  String get startSwipingMovies => 'Comece a deslizar para adicionar filmes!';

  @override
  String get noShowsInWatchlist => 'Nenhuma série na lista';

  @override
  String get startSwipingShows => 'Comece a deslizar para adicionar séries!';

  @override
  String get myWatchlistHeader => 'Minha lista';

  @override
  String moviesInLists(int movieCount, int listCount) {
    return '$movieCount filmes em $listCount listas';
  }

  @override
  String get advancedFiltersMenuItem => 'Filtros avançados';

  @override
  String get exportDataMenuItem => 'Exportar dados';

  @override
  String get searchMoviesHint => 'Pesquisar filmes...';

  @override
  String get allTagsFilter => 'Todos';

  @override
  String get listsTab => 'Listas';

  @override
  String get moviesTabLabel => 'Filmes';

  @override
  String get tagsTab => 'Etiquetas';

  @override
  String get errorLoadingLists => 'Erro ao carregar listas';

  @override
  String get tryAdjustingSearchOrFilters =>
      'Tente ajustar a pesquisa ou os filtros';

  @override
  String get noMoviesInList => 'Nenhum filme nesta lista';

  @override
  String get addMoviesToGetStarted => 'Adicione alguns filmes para começar!';

  @override
  String get noTagsYet => 'Ainda sem etiquetas';

  @override
  String get addTagsToOrganize =>
      'Adicione etiquetas aos seus filmes para organizá-los melhor';

  @override
  String get createNewListTitle => 'Criar nova lista';

  @override
  String get listNameLabel => 'Nome da lista';

  @override
  String get listNameRequired => 'Por favor, insira um nome para a lista';

  @override
  String get listDescriptionLabel => 'Descrição (opcional)';

  @override
  String get chooseColorLabel => 'Escolha uma cor:';

  @override
  String get createButton => 'Criar';

  @override
  String createdList(String name) {
    return 'Lista criada: $name';
  }

  @override
  String get exportSuccessMessage =>
      'Exportação da lista gerada localmente. O compartilhamento/download será adicionado em uma atualização futura.';

  @override
  String exportFailedMessage(String error) {
    return 'Falha ao exportar dados: $error';
  }

  @override
  String moviesWithTagCount(int count) {
    return '$count filme(s)';
  }

  @override
  String get sortTooltip => 'Ordenar';

  @override
  String get deleteTooltip => 'Excluir';

  @override
  String get noFavoriteShowsFound => 'Nenhuma série favorita encontrada';

  @override
  String get favoritesTitle => 'FAVORITOS';

  @override
  String get sortMoviesBy => 'Ordenar filmes por';

  @override
  String get sortShowsBy => 'Ordenar séries por';

  @override
  String get watchingFirstSort => 'Assistindo primeiro';

  @override
  String get finishedFirstSort => 'Terminados primeiro';

  @override
  String get titleAscendingSort => 'Título A–Z';

  @override
  String get titleDescendingSort => 'Título Z–A';

  @override
  String get yearNewestSort => 'Ano (mais recente primeiro)';

  @override
  String get yearOldestSort => 'Ano (mais antigo primeiro)';

  @override
  String get ratingHighestSort => 'Avaliação (maior primeiro)';

  @override
  String get ratingLowestSort => 'Avaliação (menor primeiro)';

  @override
  String get noFavoritesYet => 'Ainda sem favoritos';

  @override
  String get startSwipingLikeMovies => 'Comece a deslizar para curtir filmes!';

  @override
  String get errorLoadingFavorites => 'Erro ao carregar favoritos';

  @override
  String get noFavoritesFound => 'Nenhum favorito encontrado';

  @override
  String get noFavoriteShowsYet => 'Ainda sem séries favoritas';

  @override
  String get startSwipingLikeShows => 'Comece a deslizar para curtir séries!';

  @override
  String get selectMoviesToDelete => 'Selecionar filmes para excluir';

  @override
  String get selectShowsToDelete => 'Selecionar séries para excluir';

  @override
  String get deleteLabel => 'Excluir';

  @override
  String deleteItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count itens',
      one: 'Excluir 1 item',
    );
    return '$_temp0';
  }

  @override
  String get finishedBadge => 'Terminado';

  @override
  String get watchingBadge => 'Assistindo';

  @override
  String removedMoviesFromFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes removidos dos favoritos',
      one: '1 filme removido dos favoritos',
    );
    return '$_temp0';
  }

  @override
  String removedShowsFromFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries removidas dos favoritos',
      one: '1 série removida dos favoritos',
    );
    return '$_temp0';
  }

  @override
  String get profileTitle => 'PERFIL';

  @override
  String get watchlistStat => 'Minha lista';

  @override
  String get likedMoviesStat => 'Filmes curtidos';

  @override
  String get likedShowsStat => 'Séries curtidas';

  @override
  String get recentlyLikedMoviesTitle => 'Filmes curtidos recentemente';

  @override
  String get recentlyLikedShowsTitle => 'Séries curtidas recentemente';

  @override
  String get accountSettingsTitle => 'CONFIGURAÇÕES DA CONTA';

  @override
  String get editPreferencesLabel => 'Editar preferências';

  @override
  String get editPreferencesSubtitle => 'Gêneros e plataformas de streaming';

  @override
  String get notificationsLabel => 'Notificações';

  @override
  String get notificationsSubtitle => 'Push, lembretes, recomendações';

  @override
  String get privacyLabel => 'Privacidade';

  @override
  String get privacySubtitle => 'Uso de dados e seus dados';

  @override
  String get socialLabel => 'Social';

  @override
  String get socialSubtitle => 'Amigos e o que estão assistindo';

  @override
  String get helpSupportLabel => 'Ajuda e suporte';

  @override
  String get helpSupportSubtitle => 'FAQ, contato, sobre';

  @override
  String get removeAdsLabel => 'Remover anúncios';

  @override
  String get removeAdsSubtitle => 'Ainda não disponível';

  @override
  String get comingSoonTitle => 'Em breve';

  @override
  String get comingSoonMessage =>
      'O modo sem anúncios ainda não está disponível. Fique atento!';

  @override
  String get signOutButton => 'Sair';

  @override
  String get signOutTitle => 'Sair';

  @override
  String get signOutConfirmation => 'Tem certeza de que deseja sair?';

  @override
  String get loadingMovie => 'Carregando filme...';

  @override
  String get loadingShow => 'Carregando série...';

  @override
  String get notificationsPageTitle => 'NOTIFICAÇÕES';

  @override
  String get notificationsIntro => 'Escolha sobre o que deseja ser notificado.';

  @override
  String get followRequestsToggle => 'Solicitações de seguimento';

  @override
  String get followRequestsToggleSubtitle => 'Revisar quem quer te seguir';

  @override
  String get pushNotificationsToggle => 'Notificações push';

  @override
  String get pushNotificationsToggleSubtitle => 'Receber notificações do app';

  @override
  String get matchRemindersToggle => 'Lembretes de combinações';

  @override
  String get matchRemindersToggleSubtitle =>
      'Lembrar quando você obtiver uma combinação';

  @override
  String get newRecommendationsToggle => 'Novas recomendações';

  @override
  String get newRecommendationsToggleSubtitle =>
      'Atualizações quando adicionarmos novas escolhas para você';

  @override
  String get friendRequestsToggle => 'Solicitações de amizade';

  @override
  String get friendRequestsToggleSubtitle =>
      'Notificar quando alguém te seguir';

  @override
  String get followAcceptedToggle => 'Seguimento aceito';

  @override
  String get followAcceptedToggleSubtitle =>
      'Notificar quando aceitarem sua solicitação';

  @override
  String get privacyPageTitle => 'PRIVACIDADE';

  @override
  String get privacyIntro =>
      'Controle como seus dados são usados para personalizar sua experiência.';

  @override
  String get useDataRecommendations => 'Usar dados para recomendações';

  @override
  String get useDataRecommendationsSubtitle =>
      'Permitir que usemos seus curtidos, lista e atividade para melhorar suas recomendações.';

  @override
  String get socialPrivacySection => 'Privacidade social';

  @override
  String get allowFollowers => 'Permitir seguidores';

  @override
  String get allowFollowersSubtitle =>
      'Deixar outros usuários enviarem solicitações de seguimento';

  @override
  String get shareLikes => 'Compartilhar curtidas';

  @override
  String get shareLikesSubtitle => 'Seguidores podem ver o que você curte';

  @override
  String get shareWatchlist => 'Compartilhar lista';

  @override
  String get shareWatchlistSubtitle =>
      'Seguidores podem ver sua atividade na lista';

  @override
  String get shareWatchingActivity => 'Compartilhar atividade de visualização';

  @override
  String get shareWatchingActivitySubtitle =>
      'Seguidores podem ver o que você está assistindo';

  @override
  String get yourDataSection => 'Seus dados';

  @override
  String get whatWeStore => 'O que armazenamos';

  @override
  String get whatWeStoreSubtitle =>
      'Armazenamos seu e-mail, lista, curtidas, não curtidas e preferências para fornecer o serviço.';

  @override
  String get deleteMyData => 'Excluir meus dados';

  @override
  String get deleteMyDataSubtitle => 'Solicitar exclusão de conta e dados';

  @override
  String get deleteDataDialogTitle => 'Excluir meus dados';

  @override
  String get deleteDataDialogContent =>
      'Isso removerá sua conta e todos os dados associados (lista, curtidas, preferências) dos nossos servidores. Esta ação não pode ser desfeita.';

  @override
  String get deleteDataLearnMore => 'Saiba mais';

  @override
  String get deleteDataSnackbar =>
      'Para excluir sua conta, entre em contato com support@popmatch.app';

  @override
  String get helpSupportPageTitle => 'AJUDA E SUPORTE';

  @override
  String get faqSection => 'Perguntas frequentes';

  @override
  String get faq1Question => 'Como funciona o deslizamento?';

  @override
  String get faq1Answer =>
      'Deslize para a direita para curtir, para a esquerda para não curtir, para cima para uma combinação (salvar para ver depois) e para baixo para pular. Suas escolhas nos ajudam a recomendar melhor.';

  @override
  String get faq2Question => 'Como adiciono algo à minha lista?';

  @override
  String get faq2Answer =>
      'Deslize para cima em um cartão para abrir a tela de combinação, depois escolha adicionar à lista. Você também pode abrir o título e tocar no botão de lista na tela de detalhes.';

  @override
  String get faq3Question => 'Posso mudar minhas plataformas de streaming?';

  @override
  String get faq3Answer =>
      'Sim. Vá para Perfil → Editar preferências e selecione seus serviços de streaming. Usamos isso para personalizar recomendações.';

  @override
  String get faq4Question => 'Como redefino minha senha?';

  @override
  String get faq4Answer =>
      'Na tela de login, toque em \"Esqueceu a senha?\" e insira seu e-mail. Enviaremos um link para redefini-la.';

  @override
  String get contactSection => 'Entre em contato';

  @override
  String get emailSupportLabel => 'E-mail de suporte';

  @override
  String get emailSupportAddress => 'support@popmatch.app';

  @override
  String get emailErrorSnackbar =>
      'Não foi possível abrir o aplicativo de e-mail. Contato: support@popmatch.app';

  @override
  String get aboutSection => 'Sobre';

  @override
  String get aboutDescription =>
      'Descoberta de filmes e séries por deslizamento. Encontre o que assistir a seguir.';

  @override
  String get aboutVersion => 'Versão 1.0.0';

  @override
  String get editPreferencesAppBarTitle => 'Editar preferências';

  @override
  String get genrePageTitle => 'Quais gêneros você ama?';

  @override
  String get genrePageSubtitle =>
      'Selecione seus gêneros favoritos para melhores recomendações.';

  @override
  String get platformPageTitle => 'Onde você assiste filmes?';

  @override
  String get platformPageSubtitle =>
      'Selecione suas plataformas de streaming para encontrar filmes disponíveis nos seus serviços.';

  @override
  String pageIndicatorOf2(int page) {
    return '$page de 2';
  }

  @override
  String get preferencesSavedSnackbar => 'Preferências salvas com sucesso!';

  @override
  String get socialPageTitle => 'SOCIAL';

  @override
  String get friendsWatchingCard => 'O que seus amigos estão assistindo';

  @override
  String get friendsWatchingCardSubtitle =>
      'Deslize cartões com base em pessoas que você segue';

  @override
  String get findUsersSection => 'Encontrar usuários';

  @override
  String get socialSearchHint => 'Pesquisar por nome ou e-mail';

  @override
  String get followingStatus => 'Seguindo';

  @override
  String get pendingStatus => 'Pendente';

  @override
  String get followButton => 'Seguir';

  @override
  String get followRequestSentSnackbar => 'Solicitação de seguimento enviada';

  @override
  String get followRequestsSection => 'Solicitações de seguimento';

  @override
  String get noFollowRequests => 'Sem solicitações pendentes.';

  @override
  String get wantsToFollowYou => 'quer te seguir';

  @override
  String get declineButton => 'Recusar';

  @override
  String get acceptButton => 'Aceitar';

  @override
  String get friendsWatchingTitle => 'AMIGOS ASSISTINDO';

  @override
  String get feedDisabledMessage =>
      'O feed de amigos está desativado no momento.';

  @override
  String get friendsEmptyState =>
      'Nenhuma atividade de amigos ainda.\nSiga mais pessoas e volte em breve.';

  @override
  String get friendsFeedTitle => 'O que seus amigos estão assistindo';

  @override
  String get moodAppBarTitle => 'Como você está se sentindo?';

  @override
  String get moodPageTitle => 'Qual é o seu humor hoje?';

  @override
  String get moodPageSubtitle =>
      'Recomendaremos filmes que combinam com seu estado de espírito';

  @override
  String get selectMoodButton => 'Selecionar seu humor';

  @override
  String findMoodMoviesButton(String moodName) {
    return 'Encontrar filmes de $moodName';
  }

  @override
  String get advancedFiltersTitle => 'Filtros avançados';

  @override
  String get resetButton => 'Redefinir';

  @override
  String get filtersTab => 'Filtros';

  @override
  String get sortTab => 'Ordenar';

  @override
  String get resultsTab => 'Resultados';

  @override
  String get sortByTitle => 'Ordenar por';

  @override
  String get sortDirectionLabel => 'Direção de ordenação:';

  @override
  String get descendingOption => 'Decrescente';

  @override
  String get ascendingOption => 'Crescente';

  @override
  String get noMoviesMatchFilters =>
      'Nenhum filme corresponde aos seus filtros';

  @override
  String get tryAdjustingFilterCriteria =>
      'Tente ajustar os critérios de filtro';

  @override
  String applyFiltersCount(int count) {
    return 'Aplicar filtros ($count filmes)';
  }

  @override
  String resultsCount(int count) {
    return '$count resultados';
  }

  @override
  String get genresFilter => 'Gêneros';

  @override
  String get yearRangeFilter => 'Intervalo de ano';

  @override
  String get ratingRangeFilter => 'Intervalo de avaliação';

  @override
  String get minRatingLabel => 'Avaliação mínima';

  @override
  String get maxRatingLabel => 'Avaliação máxima';

  @override
  String get languagesFilter => 'Idiomas';

  @override
  String get contentTypeFilter => 'Tipo de conteúdo';

  @override
  String get allContentOption => 'Todo o conteúdo';

  @override
  String get familyFriendlyOption => 'Para toda a família';

  @override
  String get adultContentOption => 'Conteúdo adulto';

  @override
  String get availabilityFilter => 'Disponibilidade';

  @override
  String get showOnlyAvailableStream =>
      'Mostrar apenas disponível em streaming';

  @override
  String get temporarilyUnavailable =>
      'Temporariamente indisponível nesta versão';

  @override
  String get popularitySort => 'Popularidade';

  @override
  String get runtimeSort => 'Duração';

  @override
  String get releaseDateSort => 'Data de lançamento';

  @override
  String get streamingFiltersTitle => 'Filtros de streaming';

  @override
  String get clearFiltersTooltip => 'Limpar filtros';

  @override
  String get filterByPlatformTitle => 'Filtrar por plataforma de streaming';

  @override
  String get failedToLoadMovies => 'Erro ao carregar filmes';

  @override
  String get noMoviesFoundFilter => 'Nenhum filme encontrado';

  @override
  String get tryDifferentPlatforms =>
      'Tente selecionar plataformas de streaming diferentes';

  @override
  String moviesFoundCount(int count) {
    return '$count filmes encontrados';
  }

  @override
  String filteredByPlatforms(int count) {
    return 'Filtrado por $count plataforma(s)';
  }

  @override
  String get searchingText => 'Pesquisando...';

  @override
  String noResultsFor(String query) {
    return 'Sem resultados para \"$query\"';
  }

  @override
  String get tryDifferentTitleKeyword =>
      'Tente um título ou palavra-chave diferente';

  @override
  String get noShowsFound => 'Nenhuma série encontrada';

  @override
  String get recentLabel => 'Recente';

  @override
  String get clearLabel => 'Limpar';

  @override
  String get searchForMoviesHint => 'Pesquise filmes, atores ou gêneros';

  @override
  String get recentSearchesAppearHere =>
      'Suas pesquisas recentes aparecerão aqui';

  @override
  String get likedByFriendsLabel => 'Curtido por amigos';

  @override
  String get skipLabel => 'Pular';

  @override
  String get likeLabel => 'Curtir';

  @override
  String get synopsisLabel => 'Sinopse';

  @override
  String get moreLabel => 'Mais';

  @override
  String get showLessLabel => 'Mostrar menos';

  @override
  String get castCrewLabel => 'Elenco e equipe';

  @override
  String get trailersVideosLabel => 'Trailers e vídeos';

  @override
  String get moviesLikeThisLabel => 'Filmes similares';

  @override
  String get showsLikeThisLabel => 'Séries similares';

  @override
  String get failedToLoadSimilarShows => 'Erro ao carregar séries similares';

  @override
  String get noSimilarShowsFound => 'Nenhuma série similar encontrada';

  @override
  String get failedToLoadSimilarMovies => 'Erro ao carregar filmes similares';

  @override
  String get noSimilarMoviesFound => 'Nenhum filme similar encontrado';

  @override
  String get whereToWatchLabel => 'Onde assistir:';

  @override
  String removedFromFavoritesSnackbar(String title) {
    return '$title removido dos favoritos';
  }

  @override
  String addedToFavoritesSnackbar(String title) {
    return '$title adicionado aos favoritos';
  }

  @override
  String removedFromDislikedSnackbar(String title) {
    return '$title removido dos não curtidos';
  }

  @override
  String addedToDislikedSnackbar(String title) {
    return '$title adicionado aos não curtidos';
  }

  @override
  String get noSeasonsAvailable => 'Nenhuma temporada disponível';

  @override
  String seasonLabel(int number) {
    return 'Temporada $number';
  }

  @override
  String episodesLabel(int count) {
    return '$count episódios';
  }

  @override
  String get closeButton => 'Fechar';

  @override
  String minutesLabel(int count) {
    return '$count min';
  }

  @override
  String get sortDescending => 'Decrescente';

  @override
  String get sortAscending => 'Crescente';

  @override
  String get tryAdjustingFilters => 'Tente ajustar os critérios de filtro';

  @override
  String get ratingRangeLabel => 'Faixa de avaliação';

  @override
  String get languagesLabel => 'Idiomas';

  @override
  String get contentTypeLabel => 'Tipo de conteúdo';

  @override
  String get allContentLabel => 'Todo o conteúdo';

  @override
  String get familyFriendlyLabel => 'Para toda a família';

  @override
  String get adultContentLabel => 'Conteúdo adulto';

  @override
  String get availabilityLabel => 'Disponibilidade';

  @override
  String get showOnlyStreamableLabel =>
      'Mostrar apenas disponível para streaming';

  @override
  String get temporarilyUnavailableLabel =>
      'Temporariamente indisponível nesta versão';

  @override
  String get popularityOption => 'Popularidade';

  @override
  String get runtimeOption => 'Duração';

  @override
  String get releaseDateOption => 'Data de lançamento';

  @override
  String upToRatingLabel(String rating) {
    return 'Até $rating';
  }

  @override
  String get myWatchlistTitle => 'Minha lista';

  @override
  String get exportDataButton => 'Exportar dados';

  @override
  String get noMoviesMatchFiltersShort =>
      'Nenhum filme corresponde aos seus filtros';

  @override
  String get addSomeMovies => 'Adicione alguns filmes para começar!';

  @override
  String get addTagsDescription =>
      'Adicione etiquetas aos seus filmes para organizá-los melhor';

  @override
  String get listNameError => 'Por favor, insira um nome para a lista';

  @override
  String createdListSnackbar(String name) {
    return 'Lista criada: $name';
  }

  @override
  String get exportDataLocalSnackbar =>
      'Exportação de dados gerada localmente. Compartilhar/baixar será adicionado em uma atualização futura.';

  @override
  String failedToExportSnackbar(String error) {
    return 'Falha ao exportar dados: $error';
  }

  @override
  String get forYouTitle => 'Para Você';

  @override
  String get forYouTooltip => 'Para Você';

  @override
  String get forYouBecauseYouLiked => 'Porque você curtiu';

  @override
  String get forYouTrending => 'Em alta';

  @override
  String get forYouFriendsWatching => 'Seus amigos estão assistindo';

  @override
  String get premiumUpsellTitle => 'PopMatch Premium';

  @override
  String get premiumPerkUnlimitedSwipes => 'Deslizes ilimitados';

  @override
  String get premiumPerkNoAds => 'Experiência sem anúncios';

  @override
  String get premiumPerkForYou => 'Recomendações “Para Você” personalizadas';

  @override
  String get premiumUpgradeCta => 'Assinar Premium';

  @override
  String get premiumComingSoon => 'As assinaturas chegarão em breve.';

  @override
  String get premiumDevEnable => 'Ativar Premium (dev)';
}
