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
