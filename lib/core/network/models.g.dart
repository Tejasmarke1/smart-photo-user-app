part of 'models.dart';

SendOtpRequest _$SendOtpRequestFromJson(Map<String, dynamic> json) => SendOtpRequest(
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      otpType: json['otp_type'] as String,
    );

Map<String, dynamic> _$SendOtpRequestToJson(SendOtpRequest instance) => <String, dynamic>{
      'email': instance.email,
      'phone': instance.phone,
      'otp_type': instance.otpType,
    };

SendOtpResponse _$SendOtpResponseFromJson(Map<String, dynamic> json) => SendOtpResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      expiresIn: json['expires_in'] as int,
      canResendIn: json['can_resend_in'] as int,
    );

Map<String, dynamic> _$SendOtpResponseToJson(SendOtpResponse instance) => <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'expires_in': instance.expiresIn,
      'can_resend_in': instance.canResendIn,
    };

VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) => VerifyOtpRequest(
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      otpCode: json['otp_code'] as String,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(VerifyOtpRequest instance) => <String, dynamic>{
      'email': instance.email,
      'phone': instance.phone,
      'otp_code': instance.otpCode,
    };

VerifyOtpResponse _$VerifyOtpResponseFromJson(Map<String, dynamic> json) => VerifyOtpResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      userExists: json['user_exists'] as bool,
      requiresSignup: json['requires_signup'] as bool,
      tempToken: json['temp_token'] as String?,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
    );

Map<String, dynamic> _$VerifyOtpResponseToJson(VerifyOtpResponse instance) => <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'user_exists': instance.userExists,
      'requires_signup': instance.requiresSignup,
      'temp_token': instance.tempToken,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

SignupRequest _$SignupRequestFromJson(Map<String, dynamic> json) => SignupRequest(
      tempToken: json['temp_token'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );

Map<String, dynamic> _$SignupRequestToJson(SignupRequest instance) => <String, dynamic>{
      'temp_token': instance.tempToken,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'profile_picture_url': instance.profilePictureUrl,
    };

SignupResponse _$SignupResponseFromJson(Map<String, dynamic> json) => SignupResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      user: json['user'] as Map<String, dynamic>,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$SignupResponseToJson(SignupResponse instance) => <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'user': instance.user,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) => RefreshTokenRequest(
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$RefreshTokenRequestToJson(RefreshTokenRequest instance) => <String, dynamic>{
      'refresh_token': instance.refreshToken,
    };

RefreshTokenResponse _$RefreshTokenResponseFromJson(Map<String, dynamic> json) => RefreshTokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$RefreshTokenResponseToJson(RefreshTokenResponse instance) => <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

AlbumDetailResponse _$AlbumDetailResponseFromJson(Map<String, dynamic> json) => AlbumDetailResponse(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      sharingCode: json['sharing_code'] as String,
      isPublic: json['is_public'] as bool,
      passwordProtected: json['password_protected'] as bool,
      photographerName: json['photographer_name'] as String?,
      photoCount: json['photo_count'] as int,
    );

Map<String, dynamic> _$AlbumDetailResponseToJson(AlbumDetailResponse instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'cover_photo_url': instance.coverPhotoUrl,
      'sharing_code': instance.sharingCode,
      'is_public': instance.isPublic,
      'password_protected': instance.passwordProtected,
      'photographer_name': instance.photographerName,
      'photo_count': instance.photoCount,
    };

PhotoResponse _$PhotoResponseFromJson(Map<String, dynamic> json) => PhotoResponse(
      id: json['id'] as String,
      albumId: json['album_id'] as String,
      filename: json['filename'] as String,
      thumbnailSmallUrl: json['thumbnail_small_url'] as String?,
      thumbnailMediumUrl: json['thumbnail_medium_url'] as String?,
      thumbnailLargeUrl: json['thumbnail_large_url'] as String?,
      watermarkedUrl: json['watermarked_url'] as String?,
      originalUrl: json['original_url'] as String?,
    );

Map<String, dynamic> _$PhotoResponseToJson(PhotoResponse instance) => <String, dynamic>{
      'id': instance.id,
      'album_id': instance.albumId,
      'filename': instance.filename,
      'thumbnail_small_url': instance.thumbnailSmallUrl,
      'thumbnail_medium_url': instance.thumbnailMediumUrl,
      'thumbnail_large_url': instance.thumbnailLargeUrl,
      'watermarked_url': instance.watermarkedUrl,
      'original_url': instance.originalUrl,
    };

PhotoListResponse _$PhotoListResponseFromJson(Map<String, dynamic> json) => PhotoListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => PhotoResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
      pages: json['pages'] as int,
    );

Map<String, dynamic> _$PhotoListResponseToJson(PhotoListResponse instance) => <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'size': instance.size,
      'pages': instance.pages,
    };

PhotoDownloadResponse _$PhotoDownloadResponseFromJson(Map<String, dynamic> json) => PhotoDownloadResponse(
      downloadUrl: json['download_url'] as String,
      expiresIn: json['expires_in'] as int,
      filename: json['filename'] as String,
    );

Map<String, dynamic> _$PhotoDownloadResponseToJson(PhotoDownloadResponse instance) => <String, dynamic>{
      'download_url': instance.downloadUrl,
      'expires_in': instance.expiresIn,
      'filename': instance.filename,
    };

FaceSearchResponse _$FaceSearchResponseFromJson(Map<String, dynamic> json) => FaceSearchResponse(
      faceId: json['face_id'] as String,
      photoId: json['photo_id'] as String,
      similarityScore: (json['similarity_score'] as num).toDouble(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      personName: json['person_name'] as String?,
    );

Map<String, dynamic> _$FaceSearchResponseToJson(FaceSearchResponse instance) => <String, dynamic>{
      'face_id': instance.faceId,
      'photo_id': instance.photoId,
      'similarity_score': instance.similarityScore,
      'thumbnail_url': instance.thumbnailUrl,
      'person_name': instance.personName,
    };

DeviceTokenRegisterRequest _$DeviceTokenRegisterRequestFromJson(Map<String, dynamic> json) => DeviceTokenRegisterRequest(
      token: json['token'] as String,
      deviceType: json['device_type'] as String,
      deviceName: json['device_name'] as String?,
    );

Map<String, dynamic> _$DeviceTokenRegisterRequestToJson(DeviceTokenRegisterRequest instance) => <String, dynamic>{
      'token': instance.token,
      'device_type': instance.deviceType,
      'device_name': instance.deviceName,
    };

DeviceTokenResponse _$DeviceTokenResponseFromJson(Map<String, dynamic> json) => DeviceTokenResponse(
      id: json['id'] as String,
      token: json['token'] as String,
      deviceType: json['device_type'] as String,
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$DeviceTokenResponseToJson(DeviceTokenResponse instance) => <String, dynamic>{
      'id': instance.id,
      'token': instance.token,
      'device_type': instance.deviceType,
      'is_active': instance.isActive,
    };
