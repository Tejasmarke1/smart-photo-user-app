import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

// ==========================================
// Auth Schemas
// ==========================================

@JsonSerializable()
class SendOtpRequest {
  final String? email;
  final String? phone;
  @JsonKey(name: 'otp_type')
  final String otpType; // 'email' or 'phone'

  SendOtpRequest({this.email, this.phone, required this.otpType});

  factory SendOtpRequest.fromJson(Map<String, dynamic> json) => _$SendOtpRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendOtpRequestToJson(this);
}

@JsonSerializable()
class SendOtpResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  @JsonKey(name: 'can_resend_in')
  final int canResendIn;

  SendOtpResponse({required this.success, required this.message, required this.expiresIn, required this.canResendIn});

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) => _$SendOtpResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SendOtpResponseToJson(this);
}

@JsonSerializable()
class VerifyOtpRequest {
  final String? email;
  final String? phone;
  @JsonKey(name: 'otp_code')
  final String otpCode;

  VerifyOtpRequest({this.email, this.phone, required this.otpCode});

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) => _$VerifyOtpRequestFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyOtpRequestToJson(this);
}

@JsonSerializable()
class VerifyOtpResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'user_exists')
  final bool userExists;
  @JsonKey(name: 'requires_signup')
  final bool requiresSignup;
  @JsonKey(name: 'temp_token')
  final String? tempToken;
  @JsonKey(name: 'access_token')
  final String? accessToken;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  VerifyOtpResponse({
    required this.success,
    required this.message,
    required this.userExists,
    required this.requiresSignup,
    this.tempToken,
    this.accessToken,
    this.refreshToken,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) => _$VerifyOtpResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyOtpResponseToJson(this);
}

@JsonSerializable()
class SignupRequest {
  @JsonKey(name: 'temp_token')
  final String tempToken;
  final String name;
  final String? email;
  final String? phone;
  @JsonKey(name: 'profile_picture_url')
  final String? profilePictureUrl;

  SignupRequest({
    required this.tempToken,
    required this.name,
    this.email,
    this.phone,
    this.profilePictureUrl,
  });

  factory SignupRequest.fromJson(Map<String, dynamic> json) => _$SignupRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SignupRequestToJson(this);
}

@JsonSerializable()
class SignupResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> user;
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  SignupResponse({
    required this.success,
    required this.message,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) => _$SignupResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SignupResponseToJson(this);
}

@JsonSerializable()
class RefreshTokenRequest {
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) => _$RefreshTokenRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

@JsonSerializable()
class RefreshTokenResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  RefreshTokenResponse({required this.accessToken, required this.refreshToken});

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) => _$RefreshTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenResponseToJson(this);
}

// ==========================================
// Album Schemas
// ==========================================

@JsonSerializable()
class AlbumDetailResponse {
  final String id;
  final String title;
  final String? description;
  final String? location;
  @JsonKey(name: 'cover_photo_url')
  final String? coverPhotoUrl;
  @JsonKey(name: 'sharing_code')
  final String sharingCode;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'password_protected')
  final bool passwordProtected;
  @JsonKey(name: 'photographer_name')
  final String? photographerName;
  @JsonKey(name: 'photo_count')
  final int photoCount;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  AlbumDetailResponse({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.coverPhotoUrl,
    required this.sharingCode,
    required this.isPublic,
    required this.passwordProtected,
    this.photographerName,
    required this.photoCount,
    this.createdAt,
  });

  factory AlbumDetailResponse.fromJson(Map<String, dynamic> json) => _$AlbumDetailResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumDetailResponseToJson(this);
}

// ==========================================
// Photo Schemas
// ==========================================

@JsonSerializable()
class PhotoResponse {
  final String id;
  @JsonKey(name: 'album_id')
  final String albumId;
  final String filename;
  @JsonKey(name: 'thumbnail_small_url')
  final String? thumbnailSmallUrl;
  @JsonKey(name: 'thumbnail_medium_url')
  final String? thumbnailMediumUrl;
  @JsonKey(name: 'thumbnail_large_url')
  final String? thumbnailLargeUrl;
  @JsonKey(name: 'watermarked_url')
  final String? watermarkedUrl;
  @JsonKey(name: 'original_url')
  final String? originalUrl;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  PhotoResponse({
    required this.id,
    required this.albumId,
    required this.filename,
    this.thumbnailSmallUrl,
    this.thumbnailMediumUrl,
    this.thumbnailLargeUrl,
    this.watermarkedUrl,
    this.originalUrl,
    this.createdAt,
  });

  factory PhotoResponse.fromJson(Map<String, dynamic> json) => _$PhotoResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoResponseToJson(this);
}

@JsonSerializable()
class PhotoListResponse {
  final List<PhotoResponse> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  PhotoListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory PhotoListResponse.fromJson(Map<String, dynamic> json) => _$PhotoListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoListResponseToJson(this);
}

@JsonSerializable()
class PhotoDownloadResponse {
  @JsonKey(name: 'download_url')
  final String downloadUrl;
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  final String filename;

  PhotoDownloadResponse({
    required this.downloadUrl,
    required this.expiresIn,
    required this.filename,
  });

  factory PhotoDownloadResponse.fromJson(Map<String, dynamic> json) => _$PhotoDownloadResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoDownloadResponseToJson(this);
}

// ==========================================
// Face Search Schemas
// ==========================================

@JsonSerializable()
class FaceSearchResponse {
  @JsonKey(name: 'face_id')
  final String faceId;
  @JsonKey(name: 'photo_id')
  final String photoId;
  @JsonKey(name: 'similarity_score')
  final double similarityScore;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'person_name')
  final String? personName;
  @JsonKey(name: 'photo_date')
  final String? photoDate;

  FaceSearchResponse({
    required this.faceId,
    required this.photoId,
    required this.similarityScore,
    this.thumbnailUrl,
    this.personName,
    this.photoDate,
  });

  factory FaceSearchResponse.fromJson(Map<String, dynamic> json) => _$FaceSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FaceSearchResponseToJson(this);
}

// ==========================================
// Device Token Schemas
// ==========================================

@JsonSerializable()
class DeviceTokenRegisterRequest {
  final String token;
  @JsonKey(name: 'device_type')
  final String deviceType; // 'android' or 'ios'
  @JsonKey(name: 'device_name')
  final String? deviceName;

  DeviceTokenRegisterRequest({
    required this.token,
    required this.deviceType,
    this.deviceName,
  });

  factory DeviceTokenRegisterRequest.fromJson(Map<String, dynamic> json) => _$DeviceTokenRegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceTokenRegisterRequestToJson(this);
}

@JsonSerializable()
class DeviceTokenResponse {
  final String id;
  final String token;
  @JsonKey(name: 'device_type')
  final String deviceType;
  @JsonKey(name: 'is_active')
  final bool isActive;

  DeviceTokenResponse({
    required this.id,
    required this.token,
    required this.deviceType,
    required this.isActive,
  });

  factory DeviceTokenResponse.fromJson(Map<String, dynamic> json) => _$DeviceTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceTokenResponseToJson(this);
}

@JsonSerializable()
class UserUpdateRequest {
  final String? name;
  final String? email;
  final String? phone;
  @JsonKey(name: 'profile_picture_url')
  final String? profilePictureUrl;

  UserUpdateRequest({this.name, this.email, this.phone, this.profilePictureUrl});

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) => _$UserUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UserUpdateRequestToJson(this);
}

@JsonSerializable()
class UserResponse {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String role;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'profile_picture_url')
  final String? profilePictureUrl;
  @JsonKey(name: 'created_at')
  final String createdAt;

  UserResponse({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    required this.isActive,
    required this.isVerified,
    this.profilePictureUrl,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => _$UserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}

@JsonSerializable()
class PersonResponse {
  final String id;
  @JsonKey(name: 'album_id')
  final String albumId;
  final String? name;
  final String? phone;
  final String? email;
  @JsonKey(name: 'representative_face_id')
  final String? representativeFaceId;
  @JsonKey(name: 'face_count')
  final int faceCount;
  @JsonKey(name: 'created_at')
  final String createdAt;

  PersonResponse({
    required this.id,
    required this.albumId,
    this.name,
    this.phone,
    this.email,
    this.representativeFaceId,
    required this.faceCount,
    required this.createdAt,
  });

  factory PersonResponse.fromJson(Map<String, dynamic> json) => _$PersonResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PersonResponseToJson(this);
}

@JsonSerializable()
class PersonListResponse {
  final List<PersonResponse> persons;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;
  @JsonKey(name: 'has_more')
  final bool hasMore;

  PersonListResponse({
    required this.persons,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PersonListResponse.fromJson(Map<String, dynamic> json) => _$PersonListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PersonListResponseToJson(this);
}

@JsonSerializable()
class PersonThumbnailResponse {
  @JsonKey(name: 'person_id')
  final String personId;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'face_id')
  final String? faceId;
  @JsonKey(name: 's3_key')
  final String? s3Key;

  PersonThumbnailResponse({
    required this.personId,
    this.thumbnailUrl,
    this.faceId,
    this.s3Key,
  });

  factory PersonThumbnailResponse.fromJson(Map<String, dynamic> json) => _$PersonThumbnailResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PersonThumbnailResponseToJson(this);
}

@JsonSerializable()
class PersonWithPhotosResponse {
  final String id;
  @JsonKey(name: 'album_id')
  final String albumId;
  final String? name;
  @JsonKey(name: 'photo_ids')
  final List<String> photoIds;
  @JsonKey(name: 'photo_count')
  final int photoCount;

  PersonWithPhotosResponse({
    required this.id,
    required this.albumId,
    this.name,
    required this.photoIds,
    required this.photoCount,
  });

  factory PersonWithPhotosResponse.fromJson(Map<String, dynamic> json) => _$PersonWithPhotosResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PersonWithPhotosResponseToJson(this);
}

// ==========================================
// Billing & Subscriptions
// ==========================================

@JsonSerializable()
class PlanResponse {
  final String id;
  final String code;
  final String name;
  final String? description;
  @JsonKey(name: 'price_cents')
  final int priceCents;
  final String currency;
  @JsonKey(name: 'billing_cycle')
  final String billingCycle;
  @JsonKey(name: 'storage_limit_bytes')
  final int storageLimitBytes;
  @JsonKey(name: 'photo_limit')
  final int photoLimit;
  @JsonKey(name: 'video_limit')
  final int videoLimit;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final List<String>? features;

  PlanResponse({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.priceCents,
    required this.currency,
    required this.billingCycle,
    required this.storageLimitBytes,
    required this.photoLimit,
    required this.videoLimit,
    required this.isActive,
    this.features,
  });

  factory PlanResponse.fromJson(Map<String, dynamic> json) => _$PlanResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PlanResponseToJson(this);
}

@JsonSerializable()
class ApplyCouponRequest {
  final String code;
  @JsonKey(name: 'plan_id')
  final String planId;

  ApplyCouponRequest({required this.code, required this.planId});

  factory ApplyCouponRequest.fromJson(Map<String, dynamic> json) => _$ApplyCouponRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ApplyCouponRequestToJson(this);
}

@JsonSerializable()
class ApplyCouponResponse {
  final bool valid;
  @JsonKey(name: 'discount_cents')
  final int discountCents;
  @JsonKey(name: 'final_amount_cents')
  final int finalAmountCents;
  final String? message;

  ApplyCouponResponse({
    required this.valid,
    required this.discountCents,
    required this.finalAmountCents,
    this.message,
  });

  factory ApplyCouponResponse.fromJson(Map<String, dynamic> json) => _$ApplyCouponResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ApplyCouponResponseToJson(this);
}

@JsonSerializable()
class CreateOrderRequest {
  @JsonKey(name: 'amount_cents')
  final int amountCents;
  final String currency;
  @JsonKey(name: 'payment_type')
  final String paymentType;
  @JsonKey(name: 'reference_type')
  final String referenceType;
  @JsonKey(name: 'reference_id')
  final String? referenceId;
  @JsonKey(name: 'coupon_code')
  final String? couponCode;

  CreateOrderRequest({
    required this.amountCents,
    required this.currency,
    required this.paymentType,
    required this.referenceType,
    this.referenceId,
    this.couponCode,
  });

  factory CreateOrderRequest.fromJson(Map<String, dynamic> json) => _$CreateOrderRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderRequestToJson(this);
}

@JsonSerializable()
class CreateOrderResponse {
  @JsonKey(name: 'razorpay_order_id')
  final String razorpayOrderId;
  @JsonKey(name: 'amount_cents')
  final int amountCents;
  final String currency;
  @JsonKey(name: 'razorpay_key_id')
  final String? razorpayKeyId;

  CreateOrderResponse({
    required this.razorpayOrderId,
    required this.amountCents,
    required this.currency,
    this.razorpayKeyId,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) => _$CreateOrderResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderResponseToJson(this);
}

@JsonSerializable()
class VerifyPaymentRequest {
  @JsonKey(name: 'razorpay_order_id')
  final String razorpayOrderId;
  @JsonKey(name: 'razorpay_payment_id')
  final String razorpayPaymentId;
  @JsonKey(name: 'razorpay_signature')
  final String razorpaySignature;

  VerifyPaymentRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  factory VerifyPaymentRequest.fromJson(Map<String, dynamic> json) => _$VerifyPaymentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyPaymentRequestToJson(this);
}

@JsonSerializable()
class VerifyPaymentResponse {
  final String status;
  final String message;

  VerifyPaymentResponse({required this.status, required this.message});

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) => _$VerifyPaymentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyPaymentResponseToJson(this);
}

@JsonSerializable()
class ResourceUsageResponse {
  @JsonKey(name: 'used_bytes')
  final int usedBytes;
  @JsonKey(name: 'storage_limit_bytes')
  final int storageLimitBytes;
  @JsonKey(name: 'photo_count')
  final int photoCount;
  @JsonKey(name: 'photo_limit')
  final int photoLimit;
  @JsonKey(name: 'video_count')
  final int videoCount;
  @JsonKey(name: 'video_limit')
  final int videoLimit;
  @JsonKey(name: 'percent_used')
  final double percentUsed;

  ResourceUsageResponse({
    required this.usedBytes,
    required this.storageLimitBytes,
    required this.photoCount,
    required this.photoLimit,
    required this.videoCount,
    required this.videoLimit,
    required this.percentUsed,
  });

  factory ResourceUsageResponse.fromJson(Map<String, dynamic> json) => _$ResourceUsageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ResourceUsageResponseToJson(this);
}

@JsonSerializable()
class SubscriptionResponse {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'plan_id')
  final String planId;
  final String status;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  @JsonKey(name: 'auto_renew')
  final bool autoRenew;
  @JsonKey(name: 'cancelled_at')
  final String? cancelledAt;

  SubscriptionResponse({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    this.cancelledAt,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) => _$SubscriptionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionResponseToJson(this);
}

