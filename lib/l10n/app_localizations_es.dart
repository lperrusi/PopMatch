// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'PopMatch';

  @override
  String get okButton => 'OK';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get backButton => 'Atrás';

  @override
  String get nextButton => 'Siguiente';

  @override
  String get saveButton => 'Guardar';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get viewAll => 'Ver todo';

  @override
  String get loadingText => 'Cargando...';

  @override
  String get anyOption => 'Cualquiera';

  @override
  String get navDiscover => 'Descubrir';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navWatchlist => 'Mi lista';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get moviesTab => 'PELÍCULAS';

  @override
  String get showsTab => 'SERIES';

  @override
  String get signInSubtitle =>
      'Inicia sesión para seguir descubriendo películas';

  @override
  String get emailHint => 'Correo electrónico';

  @override
  String get emailErrorEmpty => 'Por favor ingresa tu correo electrónico';

  @override
  String get emailErrorInvalid =>
      'Por favor ingresa un correo electrónico válido';

  @override
  String get passwordHint => 'Contraseña';

  @override
  String get passwordErrorEmpty => 'Por favor ingresa tu contraseña';

  @override
  String get passwordErrorTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get signInButton => 'Iniciar sesión';

  @override
  String get orSeparator => 'O';

  @override
  String get continueWithGoogleButton => 'Continuar con Google';

  @override
  String get noAccountPrompt => '¿No tienes una cuenta? ';

  @override
  String get signUpLinkText => 'Regístrate';

  @override
  String get forgotPasswordButton => '¿Olvidaste tu contraseña?';

  @override
  String get joinPopMatchTitle => 'ÚNETE A POPMATCH';

  @override
  String get registerSubtitle =>
      'Crea una cuenta para empezar a descubrir películas';

  @override
  String get displayNameHint => 'Nombre de usuario';

  @override
  String get displayNameErrorEmpty => 'Por favor ingresa tu nombre de usuario';

  @override
  String get displayNameErrorTooShort =>
      'El nombre debe tener al menos 2 caracteres';

  @override
  String get confirmPasswordHint => 'Confirmar contraseña';

  @override
  String get confirmPasswordErrorEmpty => 'Por favor confirma tu contraseña';

  @override
  String get confirmPasswordErrorMismatch => 'Las contraseñas no coinciden';

  @override
  String get createAccountButton => 'Crear cuenta';

  @override
  String get alreadyHaveAccountPrompt => '¿Ya tienes una cuenta? ';

  @override
  String get signInLinkText => 'Iniciar sesión';

  @override
  String get forgotPasswordTitle => '¿OLVIDASTELA CONTRASEÑA?';

  @override
  String get checkEmailTitle => 'REVISA TU CORREO';

  @override
  String get forgotPasswordSubtitle =>
      '¡No te preocupes! Ingresa tu correo y te enviaremos instrucciones para restablecerlo.';

  @override
  String checkEmailSubtitle(String email) {
    return 'Enviamos un enlace de restablecimiento a $email';
  }

  @override
  String get sendResetLinkButton => 'Enviar enlace';

  @override
  String get resetEmailNotReceivedMessage =>
      '¿No recibiste el correo? Revisa tu carpeta de spam o inténtalo en unos minutos.';

  @override
  String get resendEmailButton => 'Reenviar correo';

  @override
  String get backToLoginButton => 'Volver al inicio de sesión';

  @override
  String get rememberPasswordPrompt => '¿Recuerdas tu contraseña? ';

  @override
  String get verifyEmailTitle => 'Verifica tu correo';

  @override
  String get verificationCodeDescription =>
      'Enviamos un código de 6 dígitos a:';

  @override
  String get verifyCodeButton => 'Verificar código';

  @override
  String get resendCodeButton => 'Reenviar código';

  @override
  String get emailVerificationHelper =>
      '¿No recibiste el código? Revisa tu spam o reenvíálo.';

  @override
  String get incompleteCodeError =>
      'Por favor ingresa el código completo de 6 dígitos';

  @override
  String get codeError => 'Por favor ingresa un código de 6 dígitos';

  @override
  String get invalidCodeError =>
      'Código de verificación inválido. Inténtalo de nuevo.';

  @override
  String get emailVerificationSuccess => '¡Correo verificado exitosamente!';

  @override
  String get verificationCodeSentMessage =>
      '¡Código enviado! Por favor revisa tu correo.';

  @override
  String get verificationCodeFallbackMessage =>
      'El servicio de correo no está disponible. Tu código fue generado en la aplicación.';

  @override
  String get verificationCodeDevMessage =>
      'Código generado en modo de desarrollo. Revisa los registros de depuración.';

  @override
  String get verificationCodeGeneratedMessage =>
      'Código de verificación generado. Inténtalo de nuevo si es necesario.';

  @override
  String get swipeToMatchTitle => 'DESLIZA PARA COINCIDIR';

  @override
  String get swipeToMatchDescription =>
      'Desliza a la derecha para dar like, a la izquierda para pasar.\nEncuentra tu película perfecta.';

  @override
  String get aiPoweredPicksTitle => 'Recomendaciones con IA';

  @override
  String get aiPoweredPicksDescription =>
      'Nuestra IA aprende tus gustos para sugerirte películas que amarás.';

  @override
  String get curateWatchlistTitle => 'Crea Tu Lista';

  @override
  String get curateWatchlistDescription =>
      'Guarda tus coincidencias y nunca dudes qué ver.';

  @override
  String get getStartedButton => 'Comenzar';

  @override
  String get welcomeTitle => '¡BIENVENIDO A POPMATCH!';

  @override
  String get welcomeSubtitle =>
      'Personalicemos tu descubrimiento de películas. Elige lo que amas y encontraremos las mejores coincidencias.';

  @override
  String get swipeFeature =>
      'Desliza para descubrir películas que te encantarán';

  @override
  String get bookmarkFeature => 'Guarda en tu lista de seguimiento';

  @override
  String get filterFeature => 'Filtra por géneros y preferencias';

  @override
  String get shareFeature => 'Comparte con amigos';

  @override
  String get genresTitle => '¿QUÉ GÉNEROS TE ENCANTAN?';

  @override
  String get genresSubtitle =>
      'Selecciona tus géneros favoritos para mejores recomendaciones.';

  @override
  String get platformsTitle => '¿DÓNDE VES PELÍCULAS?';

  @override
  String get platformsSubtitle =>
      'Selecciona los servicios de streaming que tienes.';

  @override
  String pageIndicatorOf3(int current) {
    return '$current de 3';
  }

  @override
  String get loadingGenresMessage => 'Cargando géneros...';

  @override
  String get matchSwipeUpTooltip => 'Desliza hacia arriba — Coincidencia';

  @override
  String get swipeLiked => 'Te gustó';

  @override
  String get swipePassed => 'Pasado';

  @override
  String get swipeWatchlisted => 'En lista';

  @override
  String get swipeSwiped => 'Deslizado';

  @override
  String get undoButton => 'DESHACER';

  @override
  String get matchItsA => 'Es una';

  @override
  String get matchTitle => '¡COINCIDENCIA!';

  @override
  String get savedToWatchlist => 'Guardado en tu lista';

  @override
  String get viewDetailsButton => 'Ver detalles';

  @override
  String get addToWatchlistButton => 'Añadir a la lista';

  @override
  String reasonBecauseYouLike(String genre) {
    return 'Porque te gusta $genre';
  }

  @override
  String get strategyLikedSimilar => 'Porque te gustaron títulos similares';

  @override
  String get strategyGenreMatch => 'Coincide con tus géneros';

  @override
  String get strategyTrending => 'Tendencia ahora';

  @override
  String get strategyTopRated => 'Mejor valorado';

  @override
  String get strategyPersonalized => 'Elegido para ti';

  @override
  String get strategyCurated => 'Selección del editor';

  @override
  String get strategyActorDiscovery => 'De un reparto que disfrutas';

  @override
  String get strategyDirectorDiscovery => 'De un director que disfrutas';

  @override
  String get relaxFiltersButton => 'Relajar filtros';

  @override
  String get refreshButton => 'Actualizar';

  @override
  String get applyButton => 'Aplicar';

  @override
  String get clearAllButton => 'Limpiar todo';

  @override
  String get filtersSectionTitle => 'Filtros';

  @override
  String get moodFilterLabel => 'Estado de ánimo';

  @override
  String get selectMoodsHint => 'Seleccionar ánimos';

  @override
  String get selectGenresHint => 'Seleccionar géneros';

  @override
  String get platformFilterLabel => 'Plataforma';

  @override
  String get selectPlatformsHint => 'Seleccionar plataformas';

  @override
  String get selectMoodsTitle => 'Seleccionar ánimos';

  @override
  String get selectGenresTitle => 'Seleccionar géneros';

  @override
  String get selectPlatformsTitle => 'Seleccionar plataformas';

  @override
  String get nothingHereLabel => 'Nada aquí';

  @override
  String get noMoviesFoundSwipe => 'No se encontraron películas';

  @override
  String get noShowsFoundSwipe => 'No se encontraron series';

  @override
  String get tryRefreshingMovies =>
      'Intenta actualizar para cargar más películas';

  @override
  String get tryRefreshingShows => 'Intenta actualizar para cargar más series';

  @override
  String get checkBackLaterNewReleases =>
      'Vuelve más tarde para nuevos lanzamientos';

  @override
  String get allCaughtUpLabel => 'Ya lo has visto todo';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHintMoviesShows => 'Busca películas y series...';

  @override
  String get searchMoviesAndShows => 'Busca películas y series';

  @override
  String get startTypingFindTitles =>
      'Empieza a escribir para encontrar títulos al instante';

  @override
  String addedToLikedMovies(String title) {
    return '¡$title agregado a tus películas favoritas!';
  }

  @override
  String skippedMovie(String title) {
    return 'Saltaste $title';
  }

  @override
  String get smartFiltersTitle => 'Filtros inteligentes';

  @override
  String get genresFilterLabel => 'Géneros';

  @override
  String get yearRangeFilterLabel => 'Rango de año';

  @override
  String get fromLabel => 'Desde';

  @override
  String get toLabel => 'Hasta';

  @override
  String get applyFiltersButton => 'Aplicar filtros';

  @override
  String noMoviesFoundType(String type) {
    return 'No se encontraron películas de tipo $type';
  }

  @override
  String get tryAdjustingPreferences =>
      'Intenta ajustar tus preferencias o filtros';

  @override
  String get errorLoadingRecommendations => 'Error al cargar recomendaciones';

  @override
  String get searchHint => 'Busca películas, actores o géneros...';

  @override
  String get filtersButton => 'Filtros';

  @override
  String get searchButton => 'Buscar';

  @override
  String get genreLabel => 'Género';

  @override
  String get allGenresOption => 'Todos los géneros';

  @override
  String get yearLabel => 'Año';

  @override
  String get allYearsOption => 'Todos los años';

  @override
  String get sortByLabel => 'Ordenar por';

  @override
  String get relevanceOption => 'Relevancia';

  @override
  String get ratingOption => 'Calificación';

  @override
  String get yearOption => 'Año';

  @override
  String get titleOption => 'Título';

  @override
  String get showOnlyAvailableCheckbox =>
      'Mostrar solo disponible en streaming';

  @override
  String get streamingPlatformsLabel => 'Plataformas de streaming';

  @override
  String get recentSearchesTitle => 'Búsquedas recientes';

  @override
  String get noMoviesFound => 'No se encontraron películas';

  @override
  String get tryAdjustingSearchTerms =>
      'Intenta ajustar los términos de búsqueda o filtros';

  @override
  String get searchErrorTitle => 'Error de búsqueda';

  @override
  String get overviewTab => 'Descripción';

  @override
  String get seasonsEpisodesTab => 'Temporadas y episodios';

  @override
  String snackbarRemovedFromWatchlist(String title) {
    return '$title eliminado de la lista';
  }

  @override
  String snackbarAddedToWatchlist(String title) {
    return '$title agregado a la lista';
  }

  @override
  String get watchlistTitle => 'MI LISTA';

  @override
  String get watchlistEmpty => 'Tu lista está vacía';

  @override
  String get startSwipingAddWatchlist =>
      '¡Empieza a deslizar para agregar películas y series a tu lista!';

  @override
  String removedFromWatchlist(String title) {
    return '$title eliminado de la lista';
  }

  @override
  String movedToFavorites(String title) {
    return '$title movido a Favoritos';
  }

  @override
  String markedAsDisliked(String title) {
    return '$title marcado como no me gusta';
  }

  @override
  String get likedAction => 'Me gusta';

  @override
  String get likedActionSubtitle =>
      'Agregar a Favoritos y eliminar de la lista';

  @override
  String get dislikedAction => 'No me gusta';

  @override
  String get dislikedActionSubtitle =>
      'Marcar como no me gusta y eliminar de la lista';

  @override
  String get removeAction => 'Eliminar';

  @override
  String get removeActionSubtitle => 'Eliminar solo de la lista';

  @override
  String get noMoviesInWatchlist => 'No hay películas en la lista';

  @override
  String get startSwipingMovies =>
      '¡Empieza a deslizar para agregar películas!';

  @override
  String get noShowsInWatchlist => 'No hay series en la lista';

  @override
  String get startSwipingShows => '¡Empieza a deslizar para agregar series!';

  @override
  String get myWatchlistHeader => 'Mi lista';

  @override
  String moviesInLists(int movieCount, int listCount) {
    return '$movieCount películas en $listCount listas';
  }

  @override
  String get advancedFiltersMenuItem => 'Filtros avanzados';

  @override
  String get exportDataMenuItem => 'Exportar datos';

  @override
  String get searchMoviesHint => 'Buscar películas...';

  @override
  String get allTagsFilter => 'Todo';

  @override
  String get listsTab => 'Listas';

  @override
  String get moviesTabLabel => 'Películas';

  @override
  String get tagsTab => 'Etiquetas';

  @override
  String get errorLoadingLists => 'Error al cargar listas';

  @override
  String get tryAdjustingSearchOrFilters =>
      'Intenta ajustar la búsqueda o los filtros';

  @override
  String get noMoviesInList => 'No hay películas en esta lista';

  @override
  String get addMoviesToGetStarted => '¡Agrega algunas películas para empezar!';

  @override
  String get noTagsYet => 'Aún no hay etiquetas';

  @override
  String get addTagsToOrganize =>
      'Agrega etiquetas a tus películas para organizarlas mejor';

  @override
  String get createNewListTitle => 'Crear nueva lista';

  @override
  String get listNameLabel => 'Nombre de la lista';

  @override
  String get listNameRequired => 'Por favor ingresa un nombre para la lista';

  @override
  String get listDescriptionLabel => 'Descripción (opcional)';

  @override
  String get chooseColorLabel => 'Elige un color:';

  @override
  String get createButton => 'Crear';

  @override
  String createdList(String name) {
    return 'Lista creada: $name';
  }

  @override
  String get exportSuccessMessage =>
      'Exportación de lista generada localmente. La función de compartir/descargar se agregará en una actualización futura.';

  @override
  String exportFailedMessage(String error) {
    return 'Error al exportar datos: $error';
  }

  @override
  String moviesWithTagCount(int count) {
    return '$count película(s)';
  }

  @override
  String get sortTooltip => 'Ordenar';

  @override
  String get deleteTooltip => 'Eliminar';

  @override
  String get noFavoriteShowsFound => 'No se encontraron series favoritas';

  @override
  String get favoritesTitle => 'FAVORITOS';

  @override
  String get sortMoviesBy => 'Ordenar películas por';

  @override
  String get sortShowsBy => 'Ordenar series por';

  @override
  String get watchingFirstSort => 'Viendo primero';

  @override
  String get finishedFirstSort => 'Terminadas primero';

  @override
  String get titleAscendingSort => 'Título A–Z';

  @override
  String get titleDescendingSort => 'Título Z–A';

  @override
  String get yearNewestSort => 'Año (más reciente primero)';

  @override
  String get yearOldestSort => 'Año (más antiguo primero)';

  @override
  String get ratingHighestSort => 'Calificación (mayor primero)';

  @override
  String get ratingLowestSort => 'Calificación (menor primero)';

  @override
  String get noFavoritesYet => 'Aún no tienes favoritos';

  @override
  String get startSwipingLikeMovies =>
      '¡Empieza a deslizar para dar like a películas!';

  @override
  String get errorLoadingFavorites => 'Error al cargar favoritos';

  @override
  String get noFavoritesFound => 'No se encontraron favoritos';

  @override
  String get noFavoriteShowsYet => 'Aún no tienes series favoritas';

  @override
  String get startSwipingLikeShows =>
      '¡Empieza a deslizar para dar like a series!';

  @override
  String get selectMoviesToDelete => 'Seleccionar películas para eliminar';

  @override
  String get selectShowsToDelete => 'Seleccionar series para eliminar';

  @override
  String get deleteLabel => 'Eliminar';

  @override
  String deleteItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar $count elementos',
      one: 'Eliminar 1 elemento',
    );
    return '$_temp0';
  }

  @override
  String get finishedBadge => 'Terminado';

  @override
  String get watchingBadge => 'Viendo';

  @override
  String removedMoviesFromFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count películas eliminadas de favoritos',
      one: '1 película eliminada de favoritos',
    );
    return '$_temp0';
  }

  @override
  String removedShowsFromFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series eliminadas de favoritos',
      one: '1 serie eliminada de favoritos',
    );
    return '$_temp0';
  }

  @override
  String get profileTitle => 'PERFIL';

  @override
  String get watchlistStat => 'Mi lista';

  @override
  String get likedMoviesStat => 'Películas favoritas';

  @override
  String get likedShowsStat => 'Series favoritas';

  @override
  String get recentlyLikedMoviesTitle => 'Películas favoritas recientes';

  @override
  String get recentlyLikedShowsTitle => 'Series favoritas recientes';

  @override
  String get accountSettingsTitle => 'CONFIGURACIÓN DE CUENTA';

  @override
  String get editPreferencesLabel => 'Editar preferencias';

  @override
  String get editPreferencesSubtitle => 'Géneros y plataformas de streaming';

  @override
  String get notificationsLabel => 'Notificaciones';

  @override
  String get notificationsSubtitle => 'Push, recordatorios, recomendaciones';

  @override
  String get privacyLabel => 'Privacidad';

  @override
  String get privacySubtitle => 'Uso de datos y tus datos';

  @override
  String get socialLabel => 'Social';

  @override
  String get socialSubtitle => 'Amigos y lo que están viendo';

  @override
  String get helpSupportLabel => 'Ayuda y soporte';

  @override
  String get helpSupportSubtitle => 'FAQ, contacto, acerca de';

  @override
  String get removeAdsLabel => 'Eliminar anuncios';

  @override
  String get removeAdsSubtitle => 'No disponible aún';

  @override
  String get comingSoonTitle => 'Próximamente';

  @override
  String get comingSoonMessage =>
      'El modo sin anuncios no está disponible aún. ¡Manténte atento!';

  @override
  String get signOutButton => 'Cerrar sesión';

  @override
  String get signOutTitle => 'Cerrar sesión';

  @override
  String get signOutConfirmation =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get loadingMovie => 'Cargando película...';

  @override
  String get loadingShow => 'Cargando serie...';

  @override
  String get notificationsPageTitle => 'NOTIFICACIONES';

  @override
  String get notificationsIntro => 'Elige sobre qué quieres ser notificado.';

  @override
  String get followRequestsToggle => 'Solicitudes de seguimiento';

  @override
  String get followRequestsToggleSubtitle => 'Revisar quién quiere seguirte';

  @override
  String get pushNotificationsToggle => 'Notificaciones push';

  @override
  String get pushNotificationsToggleSubtitle =>
      'Recibir notificaciones de la app';

  @override
  String get matchRemindersToggle => 'Recordatorios de coincidencias';

  @override
  String get matchRemindersToggleSubtitle =>
      'Recordarte cuando obtienes una coincidencia';

  @override
  String get newRecommendationsToggle => 'Nuevas recomendaciones';

  @override
  String get newRecommendationsToggleSubtitle =>
      'Actualizaciones cuando agregamos nuevas selecciones para ti';

  @override
  String get friendRequestsToggle => 'Solicitudes de amistad';

  @override
  String get friendRequestsToggleSubtitle =>
      'Notificar cuando alguien te sigue';

  @override
  String get followAcceptedToggle => 'Seguimiento aceptado';

  @override
  String get followAcceptedToggleSubtitle =>
      'Notificar cuando aceptan tu solicitud';

  @override
  String get privacyPageTitle => 'PRIVACIDAD';

  @override
  String get privacyIntro =>
      'Controla cómo se usan tus datos para personalizar tu experiencia.';

  @override
  String get useDataRecommendations => 'Usar datos para recomendaciones';

  @override
  String get useDataRecommendationsSubtitle =>
      'Permitir que usemos tus likes, lista y actividad para mejorar tus recomendaciones.';

  @override
  String get socialPrivacySection => 'Privacidad social';

  @override
  String get allowFollowers => 'Permitir seguidores';

  @override
  String get allowFollowersSubtitle =>
      'Dejar que otros usuarios te envíen solicitudes';

  @override
  String get shareLikes => 'Compartir likes';

  @override
  String get shareLikesSubtitle => 'Los seguidores pueden ver qué te gusta';

  @override
  String get shareWatchlist => 'Compartir lista';

  @override
  String get shareWatchlistSubtitle =>
      'Los seguidores pueden ver tu actividad en la lista';

  @override
  String get shareWatchingActivity => 'Compartir actividad de visualización';

  @override
  String get shareWatchingActivitySubtitle =>
      'Los seguidores pueden ver qué estás viendo';

  @override
  String get yourDataSection => 'Tus datos';

  @override
  String get whatWeStore => 'Qué almacenamos';

  @override
  String get whatWeStoreSubtitle =>
      'Almacenamos tu correo, lista, likes, dislikes y preferencias para brindar el servicio.';

  @override
  String get deleteMyData => 'Eliminar mis datos';

  @override
  String get deleteMyDataSubtitle => 'Solicitar eliminación de cuenta y datos';

  @override
  String get deleteDataDialogTitle => 'Eliminar mis datos';

  @override
  String get deleteDataDialogContent =>
      'Esto eliminará tu cuenta y todos los datos asociados (lista, likes, preferencias) de nuestros servidores. Esta acción no se puede deshacer.';

  @override
  String get deleteDataLearnMore => 'Más información';

  @override
  String get deleteDataSnackbar =>
      'Para eliminar tu cuenta, contacta a support@popmatch.app';

  @override
  String get helpSupportPageTitle => 'AYUDA Y SOPORTE';

  @override
  String get faqSection => 'Preguntas frecuentes';

  @override
  String get faq1Question => '¿Cómo funciona el deslizamiento?';

  @override
  String get faq1Answer =>
      'Desliza a la derecha para dar like, a la izquierda para no me gusta, hacia arriba para una coincidencia (guardar para ver después) y hacia abajo para omitir. Tus elecciones nos ayudan a recomendar mejor contenido.';

  @override
  String get faq2Question => '¿Cómo agrego algo a mi lista?';

  @override
  String get faq2Answer =>
      'Desliza hacia arriba en una tarjeta para abrir la pantalla de coincidencia, luego elige agregar a la lista. También puedes abrir el título y tocar el botón de lista en la pantalla de detalles.';

  @override
  String get faq3Question => '¿Puedo cambiar mis plataformas de streaming?';

  @override
  String get faq3Answer =>
      'Sí. Ve a Perfil → Editar preferencias y selecciona tus servicios de streaming. Los usamos para personalizar recomendaciones.';

  @override
  String get faq4Question => '¿Cómo restablezco mi contraseña?';

  @override
  String get faq4Answer =>
      'En la pantalla de inicio de sesión, toca \"¿Olvidaste tu contraseña?\" e ingresa tu correo. Te enviaremos un enlace para restablecerla.';

  @override
  String get contactSection => 'Contáctanos';

  @override
  String get emailSupportLabel => 'Correo de soporte';

  @override
  String get emailSupportAddress => 'support@popmatch.app';

  @override
  String get emailErrorSnackbar =>
      'No se pudo abrir la app de correo. Contacta: support@popmatch.app';

  @override
  String get aboutSection => 'Acerca de';

  @override
  String get aboutDescription =>
      'Descubrimiento de películas y series por deslizamiento. Encuentra qué ver a continuación.';

  @override
  String get aboutVersion => 'Versión 1.0.0';

  @override
  String get editPreferencesAppBarTitle => 'Editar preferencias';

  @override
  String get genrePageTitle => '¿Qué géneros te encantan?';

  @override
  String get genrePageSubtitle =>
      'Selecciona tus géneros favoritos para mejores recomendaciones.';

  @override
  String get platformPageTitle => '¿Dónde ves películas?';

  @override
  String get platformPageSubtitle =>
      'Selecciona tus plataformas de streaming para encontrar películas disponibles en tus servicios.';

  @override
  String pageIndicatorOf2(int page) {
    return '$page de 2';
  }

  @override
  String get preferencesSavedSnackbar =>
      '¡Preferencias guardadas exitosamente!';

  @override
  String get socialPageTitle => 'SOCIAL';

  @override
  String get friendsWatchingCard => 'Lo que tus amigos están viendo';

  @override
  String get friendsWatchingCardSubtitle =>
      'Desliza tarjetas basadas en personas que sigues';

  @override
  String get sharedWithYouCard => 'Compartido contigo';

  @override
  String get sharedWithYouCardSubtitle => 'Listas que tus amigos te enviaron';

  @override
  String get sharedWithYouPageTitle => 'COMPARTIDO CONTIGO';

  @override
  String get sharedWithYouEmptyTitle => 'Nada compartido aún';

  @override
  String get sharedWithYouEmptyBody =>
      'Cuando un amigo comparta una lista contigo, aparecerá aquí.';

  @override
  String get sharedWithYouErrorBody =>
      'No pudimos cargar las listas compartidas. Inténtalo de nuevo.';

  @override
  String sharedByLabel(String name) {
    return 'Compartido por $name';
  }

  @override
  String get sharedByFallbackName => 'Un amigo';

  @override
  String sharedListItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count títulos',
      one: '1 título',
    );
    return '$_temp0';
  }

  @override
  String get saveToMyListsButton => 'Guardar en mis listas';

  @override
  String get savedToMyListsSnackbar => 'Guardado en tus listas';

  @override
  String get sharedListExistsSnackbar => 'Ya tienes una lista con ese nombre';

  @override
  String get sharedListSaveFailedSnackbar =>
      'No se pudo guardar la lista. Inténtalo de nuevo.';

  @override
  String get shareListMenuItem => 'Compartir con un amigo';

  @override
  String get shareListEmptySnackbar =>
      'Esta lista está vacía: agrega títulos antes de compartir.';

  @override
  String get shareListNoFriendsSnackbar =>
      'Sigue a alguien primero para compartir una lista.';

  @override
  String get shareListPickFriendTitle => 'Compartir con…';

  @override
  String listSharedSnackbar(String name) {
    return 'Compartido con $name';
  }

  @override
  String get shareListFailedSnackbar =>
      'No se pudo compartir la lista. Inténtalo de nuevo.';

  @override
  String get findUsersSection => 'Encontrar usuarios';

  @override
  String get socialSearchHint => 'Buscar por nombre o correo';

  @override
  String get followingStatus => 'Siguiendo';

  @override
  String get pendingStatus => 'Pendiente';

  @override
  String get followButton => 'Seguir';

  @override
  String get followRequestSentSnackbar => 'Solicitud de seguimiento enviada';

  @override
  String get followRequestsSection => 'Solicitudes de seguimiento';

  @override
  String get noFollowRequests => 'Sin solicitudes pendientes.';

  @override
  String get wantsToFollowYou => 'quiere seguirte';

  @override
  String get declineButton => 'Rechazar';

  @override
  String get acceptButton => 'Aceptar';

  @override
  String get friendsWatchingTitle => 'AMIGOS VIENDO';

  @override
  String get feedDisabledMessage =>
      'El feed de amigos está desactivado actualmente.';

  @override
  String get friendsEmptyState =>
      'Aún no hay actividad de amigos.\nSigue a más personas y vuelve pronto.';

  @override
  String get friendsFeedTitle => 'Lo que tus amigos están viendo';

  @override
  String get moodAppBarTitle => '¿Cómo te sientes?';

  @override
  String get moodPageTitle => '¿Cuál es tu estado de ánimo hoy?';

  @override
  String get moodPageSubtitle =>
      'Te recomendaremos películas que se adapten a tu momento';

  @override
  String get selectMoodButton => 'Selecciona tu estado de ánimo';

  @override
  String findMoodMoviesButton(String moodName) {
    return 'Encontrar películas de $moodName';
  }

  @override
  String get advancedFiltersTitle => 'Filtros avanzados';

  @override
  String get resetButton => 'Restablecer';

  @override
  String get filtersTab => 'Filtros';

  @override
  String get sortTab => 'Ordenar';

  @override
  String get resultsTab => 'Resultados';

  @override
  String get sortByTitle => 'Ordenar por';

  @override
  String get sortDirectionLabel => 'Dirección de orden:';

  @override
  String get descendingOption => 'Descendente';

  @override
  String get ascendingOption => 'Ascendente';

  @override
  String get noMoviesMatchFilters =>
      'Ninguna película coincide con tus filtros';

  @override
  String get tryAdjustingFilterCriteria =>
      'Intenta ajustar los criterios de filtro';

  @override
  String applyFiltersCount(int count) {
    return 'Aplicar filtros ($count películas)';
  }

  @override
  String resultsCount(int count) {
    return '$count resultados';
  }

  @override
  String get genresFilter => 'Géneros';

  @override
  String get yearRangeFilter => 'Rango de año';

  @override
  String get ratingRangeFilter => 'Rango de calificación';

  @override
  String get minRatingLabel => 'Calificación mínima';

  @override
  String get maxRatingLabel => 'Calificación máxima';

  @override
  String get languagesFilter => 'Idiomas';

  @override
  String get contentTypeFilter => 'Tipo de contenido';

  @override
  String get allContentOption => 'Todo el contenido';

  @override
  String get familyFriendlyOption => 'Apto para familia';

  @override
  String get adultContentOption => 'Contenido adulto';

  @override
  String get availabilityFilter => 'Disponibilidad';

  @override
  String get showOnlyAvailableStream => 'Mostrar solo disponible en streaming';

  @override
  String get temporarilyUnavailable =>
      'Temporalmente no disponible en esta versión';

  @override
  String get popularitySort => 'Popularidad';

  @override
  String get runtimeSort => 'Duración';

  @override
  String get releaseDateSort => 'Fecha de estreno';

  @override
  String get streamingFiltersTitle => 'Filtros de streaming';

  @override
  String get clearFiltersTooltip => 'Limpiar filtros';

  @override
  String get filterByPlatformTitle => 'Filtrar por plataforma de streaming';

  @override
  String get failedToLoadMovies => 'Error al cargar películas';

  @override
  String get noMoviesFoundFilter => 'No se encontraron películas';

  @override
  String get tryDifferentPlatforms =>
      'Intenta seleccionar diferentes plataformas de streaming';

  @override
  String moviesFoundCount(int count) {
    return '$count películas encontradas';
  }

  @override
  String filteredByPlatforms(int count) {
    return 'Filtrado por $count plataforma(s)';
  }

  @override
  String get searchingText => 'Buscando...';

  @override
  String noResultsFor(String query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get tryDifferentTitleKeyword =>
      'Intenta con un título o palabra clave diferente';

  @override
  String get noShowsFound => 'No se encontraron series';

  @override
  String get recentLabel => 'Reciente';

  @override
  String get clearLabel => 'Limpiar';

  @override
  String get searchForMoviesHint => 'Busca películas, actores o géneros';

  @override
  String get recentSearchesAppearHere =>
      'Tus búsquedas recientes aparecerán aquí';

  @override
  String get likedByFriendsLabel => 'Le gustó a amigos';

  @override
  String get skipLabel => 'Omitir';

  @override
  String get likeLabel => 'Me gusta';

  @override
  String get synopsisLabel => 'Sinopsis';

  @override
  String get moreLabel => 'Más';

  @override
  String get showLessLabel => 'Mostrar menos';

  @override
  String get castCrewLabel => 'Reparto y equipo';

  @override
  String get trailersVideosLabel => 'Tráileres y vídeos';

  @override
  String get moviesLikeThisLabel => 'Películas similares';

  @override
  String get showsLikeThisLabel => 'Series similares';

  @override
  String get failedToLoadSimilarShows => 'Error al cargar series similares';

  @override
  String get noSimilarShowsFound => 'No se encontraron series similares';

  @override
  String get failedToLoadSimilarMovies => 'Error al cargar películas similares';

  @override
  String get noSimilarMoviesFound => 'No se encontraron películas similares';

  @override
  String get whereToWatchLabel => 'Dónde ver:';

  @override
  String removedFromFavoritesSnackbar(String title) {
    return '$title eliminado de favoritos';
  }

  @override
  String addedToFavoritesSnackbar(String title) {
    return '$title agregado a favoritos';
  }

  @override
  String removedFromDislikedSnackbar(String title) {
    return '$title eliminado de no me gusta';
  }

  @override
  String addedToDislikedSnackbar(String title) {
    return '$title agregado a no me gusta';
  }

  @override
  String get noSeasonsAvailable => 'No hay temporadas disponibles';

  @override
  String seasonLabel(int number) {
    return 'Temporada $number';
  }

  @override
  String episodesLabel(int count) {
    return '$count episodios';
  }

  @override
  String get closeButton => 'Cerrar';

  @override
  String minutesLabel(int count) {
    return '$count min';
  }

  @override
  String get sortDescending => 'Descendente';

  @override
  String get sortAscending => 'Ascendente';

  @override
  String get tryAdjustingFilters => 'Intenta ajustar los criterios de filtro';

  @override
  String get ratingRangeLabel => 'Rango de calificación';

  @override
  String get languagesLabel => 'Idiomas';

  @override
  String get contentTypeLabel => 'Tipo de contenido';

  @override
  String get allContentLabel => 'Todo el contenido';

  @override
  String get familyFriendlyLabel => 'Apto para familia';

  @override
  String get adultContentLabel => 'Contenido adulto';

  @override
  String get availabilityLabel => 'Disponibilidad';

  @override
  String get showOnlyStreamableLabel =>
      'Mostrar solo disponibles para transmisión';

  @override
  String get temporarilyUnavailableLabel =>
      'Temporalmente no disponible en esta versión';

  @override
  String get popularityOption => 'Popularidad';

  @override
  String get runtimeOption => 'Duración';

  @override
  String get releaseDateOption => 'Fecha de estreno';

  @override
  String upToRatingLabel(String rating) {
    return 'Hasta $rating';
  }

  @override
  String get myWatchlistTitle => 'Mi lista';

  @override
  String get exportDataButton => 'Exportar datos';

  @override
  String get noMoviesMatchFiltersShort =>
      'Ninguna película coincide con tus filtros';

  @override
  String get addSomeMovies => '¡Agrega algunas películas para empezar!';

  @override
  String get addTagsDescription =>
      'Agrega etiquetas a tus películas para organizarlas mejor';

  @override
  String get listNameError => 'Por favor, ingresa un nombre para la lista';

  @override
  String createdListSnackbar(String name) {
    return 'Lista creada: $name';
  }

  @override
  String get exportDataLocalSnackbar =>
      'Exportación de datos generada localmente. Compartir/descargar se agregará en una actualización futura.';

  @override
  String failedToExportSnackbar(String error) {
    return 'Error al exportar datos: $error';
  }

  @override
  String get listsTooltip => 'Tus listas';

  @override
  String get addToListTitle => 'Añadir a lista';

  @override
  String get listNameExists => 'Ya existe una lista con ese nombre.';

  @override
  String get noListsYet => 'Aún no hay listas: crea una abajo.';

  @override
  String get newListHint => 'Nombre de la nueva lista';

  @override
  String get tagsLabel => 'Etiquetas';

  @override
  String get addTagHint => 'Añadir etiqueta';

  @override
  String get forYouTitle => 'Para Ti';

  @override
  String get forYouTooltip => 'Para Ti';

  @override
  String get forYouBecauseYouLiked => 'Porque te gustó';

  @override
  String get forYouRecommended => 'Recomendado para ti';

  @override
  String get forYouTrending => 'Tendencias';

  @override
  String get forYouFriendsWatching => 'Tus amigos están viendo';

  @override
  String get forYouTopPick => 'Selección para ti';

  @override
  String get forYouCurating => 'Seleccionando tus recomendaciones…';

  @override
  String get forYouOpen => 'Abrir';

  @override
  String get forYouEmpty =>
      'Marca algunos títulos y tus recomendaciones personalizadas aparecerán aquí.';

  @override
  String get premiumUpsellTitle => 'PopMatch Premium';

  @override
  String get premiumPerkUnlimitedSwipes => 'Deslizamientos ilimitados';

  @override
  String get premiumPerkNoAds => 'Experiencia sin anuncios';

  @override
  String get premiumPerkForYou => 'Recomendaciones “Para Ti” personalizadas';

  @override
  String get premiumUpgradeCta => 'Obtener Premium';

  @override
  String get premiumComingSoon => 'Las suscripciones llegarán pronto.';

  @override
  String get premiumDevEnable => 'Activar Premium (dev)';

  @override
  String get signInFailedError =>
      'Error al iniciar sesión. Inténtalo de nuevo.';

  @override
  String get resetEnterCodeTitle => 'INGRESA EL CÓDIGO';

  @override
  String resetCodeSentTo(String email) {
    return 'Enviamos un código de 6 dígitos a $email';
  }

  @override
  String get resetDoneTitle => 'CONTRASEÑA RESTABLECIDA';

  @override
  String get resetDoneSubtitle => 'Tu contraseña ha sido actualizada.';

  @override
  String get resetCodeOnItsWay =>
      'Si existe una cuenta con ese correo, el código está en camino.';

  @override
  String get resetEnterCodeError => 'Ingresa el código de 6 dígitos.';

  @override
  String get sendCodeButton => 'Enviar código';

  @override
  String get newPasswordHint => 'Nueva contraseña';

  @override
  String get confirmNewPasswordHint => 'Confirmar nueva contraseña';

  @override
  String get resetPasswordButton => 'Restablecer contraseña';

  @override
  String get backToSignInButton => 'Volver a iniciar sesión';

  @override
  String resendCodeInSeconds(int seconds) {
    return 'Reenviar código en ${seconds}s';
  }

  @override
  String get passwordStrengthWeak => 'Débil';

  @override
  String get passwordStrengthFair => 'Aceptable';

  @override
  String get passwordStrengthStrong => 'Fuerte';

  @override
  String get continueButton => 'Continuar';

  @override
  String get resetNewPasswordTitle => 'NUEVA CONTRASEÑA';

  @override
  String get resetNewPasswordSubtitle =>
      'Elige una nueva contraseña para tu cuenta.';
}
