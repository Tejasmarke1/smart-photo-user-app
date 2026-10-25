// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendOtpRequest _$SendOtpRequestFromJson(Map<String, dynamic> json) =>
    SendOtpRequest(
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      otpType: json['otp_type'] as String,
    );

Map<String, dynamic> _$SendOtpRequestToJson(SendOtpRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'phone': instance.phone,
      'otp_type': instance.otpType,
    };

SendOtpResponse _$SendOtpResponseFromJson(Map<String, dynamic> json) =>
    SendOtpResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      canResendIn: (json['can_resend_in'] as num).toInt(),
    );

Map<String, dynamic> _$SendOtpResponseToJson(SendOtpResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'expires_in': instance.expiresIn,
      'can_resend_in': instance.canResendIn,
    };

VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    VerifyOtpRequest(
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      otpCode: json['otp_code'] as String,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(VerifyOtpRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'phone': instance.phone,
      'otp_code': instance.otpCode,
    };

VerifyOtpResponse _$VerifyOtpResponseFromJson(Map<String, dynamic> json) =>
    VerifyOtpResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      userExists: json['user_exists'] as bool,
      requiresSignup: json['requires_signup'] as bool,
      tempToken: json['temp_token'] as String?,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
    );

Map<String, dynamic> _$VerifyOtpResponseToJson(VerifyOtpResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'user_exists': instance.userExists,
      'requires_signup': instance.requiresSignup,
      'temp_token': instance.tempToken,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

SignupRequest _$SignupRequestFromJson(Map<String, dynamic> json) =>
    SignupRequest(
      tempToken: json['temp_token'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );

Map<String, dynamic> _$SignupRequestToJson(SignupRequest instance) =>
    <String, dynamic>{
      'temp_token': instance.tempToken,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'profile_picture_url': instance.profilePictureUrl,
    };

SignupResponse _$SignupResponseFromJson(Map<String, dynamic> json) =>
    SignupResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      user: json['user'] as Map<String, dynamic>,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$SignupResponseToJson(SignupResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'user': instance.user,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    RefreshTokenRequest(
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$RefreshTokenRequestToJson(
        RefreshTokenRequest instance) =>
    <String, dynamic>{
      'refresh_token': instance.refreshToken,
    };

RefreshTokenResponse _$RefreshTokenResponseFromJson(
        Map<String, dynamic> json) =>
    RefreshTokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$RefreshTokenResponseToJson(
        RefreshTokenResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

AlbumDetailResponse _$AlbumDetailResponseFromJson(Map<String, dynamic> json) =>
    AlbumDetailResponse(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      sharingCode: json['sharing_code'] as String,
      isPublic: json['is_public'] as bool,
      passwordProtected: json['password_protected'] as bool,
      photographerName: json['photographer_name'] as String?,
      photoCount: (json['photo_count'] as num).toInt(),
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$AlbumDetailResponseToJson(
        AlbumDetailResponse instance) =>
    <String, dynamic>{
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
      'created_at': instance.createdAt,
    };

PhotoResponse _$PhotoResponseFromJson(Map<String, dynamic> json) =>
    PhotoResponse(
      id: json['id'] as String,
      albumId: json['album_id'] as String,
      filename: json['filename'] as String,
      thumbnailSmallUrl: json['thumbnail_small_url'] as String?,
      thumbnailMediumUrl: json['thumbnail_medium_url'] as String?,
      thumbnailLargeUrl: json['thumbnail_large_url'] as String?,
      watermarkedUrl: json['watermarked_url'] as String?,
      originalUrl: json['original_url'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$PhotoResponseToJson(PhotoResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'album_id': instance.albumId,
      'filename': instance.filename,
      'thumbnail_small_url': instance.thumbnailSmallUrl,
      'thumbnail_medium_url': instance.thumbnailMediumUrl,
      'thumbnail_large_url': instance.thumbnailLargeUrl,
      'watermarked_url': instance.watermarkedUrl,
      'original_url': instance.originalUrl,
      'created_at': instance.createdAt,
    };

PhotoListResponse _$PhotoListResponseFromJson(Map<String, dynamic> json) =>
    PhotoListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => PhotoResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$PhotoListResponseToJson(PhotoListResponse instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'size': instance.size,
      'pages': instance.pages,
    };

PhotoDownloadResponse _$PhotoDownloadResponseFromJson(
        Map<String, dynamic> json) =>
    PhotoDownloadResponse(
      downloadUrl: json['download_url'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      filename: json['filename'] as String,
    );

Map<String, dynamic> _$PhotoDownloadResponseToJson(
        PhotoDownloadResponse instance) =>
    <String, dynamic>{
      'download_url': instance.downloadUrl,
      'expires_in': instance.expiresIn,
      'filename': instance.filename,
    };

FaceSearchResponse _$FaceSearchResponseFromJson(Map<String, dynamic> json) =>
    FaceSearchResponse(
      faceId: json['face_id'] as String,
      photoId: json['photo_id'] as String,
      similarityScore: (json['similarity_score'] as num).toDouble(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      personName: json['person_name'] as String?,
      photoDate: json['photo_date'] as String?,
    );

Map<String, dynamic> _$FaceSearchResponseToJson(FaceSearchResponse instance) =>
    <String, dynamic>{
      'face_id': instance.faceId,
      'photo_id': instance.photoId,
      'similarity_score': instance.similarityScore,
      'thumbnail_url': instance.thumbnailUrl,
      'person_name': instance.personName,
      'photo_date': instance.photoDate,
    };

DeviceTokenRegisterRequest _$DeviceTokenRegisterRequestFromJson(
        Map<String, dynamic> json) =>
    DeviceTokenRegisterRequest(
      token: json['token'] as String,
      deviceType: json['device_type'] as String,
      deviceName: json['device_name'] as String?,
    );

Map<String, dynamic> _$DeviceTokenRegisterRequestToJson(
        DeviceTokenRegisterRequest instance) =>
    <String, dynamic>{
      'token': instance.token,
      'device_type': instance.deviceType,
      'device_name': instance.deviceName,
    };

DeviceTokenResponse _$DeviceTokenResponseFromJson(Map<String, dynamic> json) =>
    DeviceTokenResponse(
      id: json['id'] as String,
      token: json['token'] as String,
      deviceType: json['device_type'] as String,
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$DeviceTokenResponseToJson(
        DeviceTokenResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'token': instance.token,
      'device_type': instance.deviceType,
      'is_active': instance.isActive,
    };

UserUpdateRequest _$UserUpdateRequestFromJson(Map<String, dynamic> json) =>
    UserUpdateRequest(
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );

Map<String, dynamic> _$UserUpdateRequestToJson(UserUpdateRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'profile_picture_url': instance.profilePictureUrl,
    };

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      isVerified: json['is_verified'] as bool,
      profilePictureUrl: json['profile_picture_url'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.role,
      'is_active': instance.isActive,
      'is_verified': instance.isVerified,
      'profile_picture_url': instance.profilePictureUrl,
      'created_at': instance.createdAt,
    };

PersonResponse _$PersonResponseFromJson(Map<String, dynamic> json) =>
    PersonResponse(
      id: json['id'] as String,
      albumId: json['album_id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      representativeFaceId: json['representative_face_id'] as String?,
      faceCount: (json['face_count'] as num).toInt(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$PersonResponseToJson(PersonResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'album_id': instance.albumId,
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'representative_face_id': instance.representativeFaceId,
      'face_count': instance.faceCount,
      'created_at': instance.createdAt,
    };

PersonListResponse _$PersonListResponseFromJson(Map<String, dynamic> json) =>
    PersonListResponse(
      persons: (json['persons'] as List<dynamic>)
          .map((e) => PersonResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      hasMore: json['has_more'] as bool,
    );

Map<String, dynamic> _$PersonListResponseToJson(PersonListResponse instance) =>
    <String, dynamic>{
      'persons': instance.persons,
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
      'has_more': instance.hasMore,
    };

PersonThumbnailResponse _$PersonThumbnailResponseFromJson(
        Map<String, dynamic> json) =>
    PersonThumbnailResponse(
      personId: json['person_id'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      faceId: json['face_id'] as String?,
      s3Key: json['s3_key'] as String?,
    );

Map<String, dynamic> _$PersonThumbnailResponseToJson(
        PersonThumbnailResponse instance) =>
    <String, dynamic>{
      'person_id': instance.personId,
      'thumbnail_url': instance.thumbnailUrl,
      'face_id': instance.faceId,
      's3_key': instance.s3Key,
    };

PersonWithPhotosResponse _$PersonWithPhotosResponseFromJson(
        Map<String, dynamic> json) =>
    PersonWithPhotosResponse(
      id: json['id'] as String,
      albumId: json['album_id'] as String,
      name: json['name'] as String?,
      photoIds:
          (json['photo_ids'] as List<dynamic>).map((e) => e as String).toList(),
      photoCount: (json['photo_count'] as num).toInt(),
    );

Map<String, dynamic> _$PersonWithPhotosResponseToJson(
        PersonWithPhotosResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'album_id': instance.albumId,
      'name': instance.name,
      'photo_ids': instance.photoIds,
      'photo_count': instance.photoCount,
    };

PlanResponse _$PlanResponseFromJson(Map<String, dynamic> json) => PlanResponse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      priceCents: (json['price_cents'] as num).toInt(),
      currency: json['currency'] as String,
      billingCycle: json['billing_cycle'] as String,
      storageLimitBytes: (json['storage_limit_bytes'] as num).toInt(),
      photoLimit: (json['photo_limit'] as num).toInt(),
      videoLimit: (json['video_limit'] as num).toInt(),
      isActive: json['is_active'] as bool,
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PlanResponseToJson(PlanResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'price_cents': instance.priceCents,
      'currency': instance.currency,
      'billing_cycle': instance.billingCycle,
      'storage_limit_bytes': instance.storageLimitBytes,
      'photo_limit': instance.photoLimit,
      'video_limit': instance.videoLimit,
      'is_active': instance.isActive,
      'features': instance.features,
    };

ApplyCouponRequest _$ApplyCouponRequestFromJson(Map<String, dynamic> json) =>
    ApplyCouponRequest(
      code: json['code'] as String,
      planId: json['plan_id'] as String,
    );

Map<String, dynamic> _$ApplyCouponRequestToJson(ApplyCouponRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'plan_id': instance.planId,
    };

ApplyCouponResponse _$ApplyCouponResponseFromJson(Map<String, dynamic> json) =>
    ApplyCouponResponse(
      valid: json['valid'] as bool,
      discountCents: (json['discount_cents'] as num).toInt(),
      finalAmountCents: (json['final_amount_cents'] as num).toInt(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ApplyCouponResponseToJson(
        ApplyCouponResponse instance) =>
    <String, dynamic>{
      'valid': instance.valid,
      'discount_cents': instance.discountCents,
      'final_amount_cents': instance.finalAmountCents,
      'message': instance.message,
    };

CreateOrderRequest _$CreateOrderRequestFromJson(Map<String, dynamic> json) =>
    CreateOrderRequest(
      amountCents: (json['amount_cents'] as num).toInt(),
      currency: json['currency'] as String,
      paymentType: json['payment_type'] as String,
      referenceType: json['reference_type'] as String,
      referenceId: json['reference_id'] as String?,
      couponCode: json['coupon_code'] as String?,
    );

Map<String, dynamic> _$CreateOrderRequestToJson(CreateOrderRequest instance) =>
    <String, dynamic>{
      'amount_cents': instance.amountCents,
      'currency': instance.currency,
      'payment_type': instance.paymentType,
      'reference_type': instance.referenceType,
      'reference_id': instance.referenceId,
      'coupon_code': instance.couponCode,
    };

CreateOrderResponse _$CreateOrderResponseFromJson(Map<String, dynamic> json) =>
    CreateOrderResponse(
      razorpayOrderId: json['razorpay_order_id'] as String,
      amountCents: (json['amount_cents'] as num).toInt(),
      currency: json['currency'] as String,
      razorpayKeyId: json['razorpay_key_id'] as String?,
    );

Map<String, dynamic> _$CreateOrderResponseToJson(
        CreateOrderResponse instance) =>
    <String, dynamic>{
      'razorpay_order_id': instance.razorpayOrderId,
      'amount_cents': instance.amountCents,
      'currency': instance.currency,
      'razorpay_key_id': instance.razorpayKeyId,
    };

VerifyPaymentRequest _$VerifyPaymentRequestFromJson(
        Map<String, dynamic> json) =>
    VerifyPaymentRequest(
      razorpayOrderId: json['razorpay_order_id'] as String,
      razorpayPaymentId: json['razorpay_payment_id'] as String,
      razorpaySignature: json['razorpay_signature'] as String,
    );

Map<String, dynamic> _$VerifyPaymentRequestToJson(
        VerifyPaymentRequest instance) =>
    <String, dynamic>{
      'razorpay_order_id': instance.razorpayOrderId,
      'razorpay_payment_id': instance.razorpayPaymentId,
      'razorpay_signature': instance.razorpaySignature,
    };

VerifyPaymentResponse _$VerifyPaymentResponseFromJson(
        Map<String, dynamic> json) =>
    VerifyPaymentResponse(
      status: json['status'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$VerifyPaymentResponseToJson(
        VerifyPaymentResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
    };

ResourceUsageResponse _$ResourceUsageResponseFromJson(
        Map<String, dynamic> json) =>
    ResourceUsageResponse(
      usedBytes: (json['used_bytes'] as num).toInt(),
      storageLimitBytes: (json['storage_limit_bytes'] as num).toInt(),
      photoCount: (json['photo_count'] as num).toInt(),
      photoLimit: (json['photo_limit'] as num).toInt(),
      videoCount: (json['video_count'] as num).toInt(),
      videoLimit: (json['video_limit'] as num).toInt(),
      percentUsed: (json['percent_used'] as num).toDouble(),
    );

Map<String, dynamic> _$ResourceUsageResponseToJson(
        ResourceUsageResponse instance) =>
    <String, dynamic>{
      'used_bytes': instance.usedBytes,
      'storage_limit_bytes': instance.storageLimitBytes,
      'photo_count': instance.photoCount,
      'photo_limit': instance.photoLimit,
      'video_count': instance.videoCount,
      'video_limit': instance.videoLimit,
      'percent_used': instance.percentUsed,
    };

SubscriptionResponse _$SubscriptionResponseFromJson(
        Map<String, dynamic> json) =>
    SubscriptionResponse(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      status: json['status'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      autoRenew: json['auto_renew'] as bool,
      cancelledAt: json['cancelled_at'] as String?,
    );

Map<String, dynamic> _$SubscriptionResponseToJson(
        SubscriptionResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'plan_id': instance.planId,
      'status': instance.status,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'auto_renew': instance.autoRenew,
      'cancelled_at': instance.cancelledAt,
    };
