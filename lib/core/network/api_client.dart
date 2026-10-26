import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import 'models.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  /// Uses [AppConfig.apiBaseUrl] unless [baseUrl] is given.
  factory ApiClient(Dio dio, {String? baseUrl}) =>
      _ApiClient(dio, baseUrl: baseUrl ?? AppConfig.apiBaseUrl);

  // ==========================================
  // Authentication
  // ==========================================

  @POST("/auth/send-otp")
  Future<SendOtpResponse> sendOtp(@Body() SendOtpRequest request);

  @POST("/auth/verify-otp")
  Future<VerifyOtpResponse> verifyOtp(@Body() VerifyOtpRequest request);

  @POST("/auth/signup")
  Future<SignupResponse> signup(@Body() SignupRequest request);

  /// Signed-in callers authenticate with the Dio bearer token; during signup,
  /// pass the temp token from verify-otp as [signupToken].
  @POST("/auth/profile-picture")
  @MultiPart()
  Future<dynamic> uploadProfilePicture(
    @Part(name: "file") File file, {
    @Header("X-Signup-Token") String? signupToken,
  });

  @POST("/auth/refresh")
  Future<RefreshTokenResponse> refreshToken(@Body() RefreshTokenRequest request);

  @GET("/auth/me")
  Future<dynamic> getCurrentUser();

  // ==========================================
  // Albums
  // ==========================================

  @GET("/albums/code/{sharing_code}")
  Future<AlbumDetailResponse> resolveAlbumCode(@Path("sharing_code") String sharingCode);

  @GET("/albums/{album_id}")
  Future<AlbumDetailResponse> getAlbumDetail(
    @Path("album_id") String albumId,
    @Query("sharing_code") String? sharingCode,
  );

  @POST("/albums/")
  Future<AlbumDetailResponse> createAlbum(@Body() Map<String, dynamic> body);

  // ==========================================
  // Photos
  // ==========================================

  @GET("/photos/album/{album_id}")
  Future<PhotoListResponse> listPhotos(
    @Path("album_id") String albumId,
    @Query("sharing_code") String? sharingCode,
    @Query("page") int page,
    @Query("size") int size,
  );

  @POST("/photos/{photo_id}/download")
  Future<PhotoDownloadResponse> downloadPhoto(
    @Path("photo_id") String photoId,
    @Body() Map<String, dynamic> body, // Should include quality, watermark and optionally sharing_code inside extra_data
  );

  // ==========================================
  // Face search
  // ==========================================

  @POST("/faces/search/by-selfie")
  @MultiPart()
  Future<List<FaceSearchResponse>> searchBySelfie(
    @Part(name: "file") File file,
    @Query("album_id") String? albumId,
    @Query("sharing_code") String? sharingCode,
    @Query("k") int k,
    @Query("threshold") double threshold,
  );

  @POST("/faces/detect-live")
  @MultiPart()
  Future<dynamic> detectLiveFace(@Part(name: "file") File file);

  // ==========================================
  // Device tokens for push notifications
  // ==========================================

  @POST("/device-tokens/register")
  Future<DeviceTokenResponse> registerDeviceToken(@Body() DeviceTokenRegisterRequest request);

  @DELETE("/device-tokens/{token}")
  Future<void> unregisterDeviceToken(@Path("token") String token);

  // ==========================================
  // Uploads
  // ==========================================

  @POST("/uploads/albums/{album_id}/presign")
  Future<dynamic> getPresignedUrl(
    @Path("album_id") String albumId,
    @Body() Map<String, dynamic> body,
  );

  @POST("/uploads/albums/{album_id}/notify_upload")
  Future<dynamic> completeUpload(
    @Path("album_id") String albumId,
    @Body() Map<String, dynamic> body,
  );

  // ==========================================
  // Additional profile & person endpoints
  // ==========================================

  @PATCH("/auth/me")
  Future<UserResponse> updateProfile(@Body() UserUpdateRequest request);

  @GET("/persons")
  Future<PersonListResponse> listPersons(
    @Query("album_id") String? albumId,
    @Query("skip") int skip,
    @Query("limit") int limit,
  );

  @GET("/persons/{person_id}/thumbnail")
  Future<PersonThumbnailResponse> getPersonThumbnail(
    @Path("person_id") String personId,
    @Query("size") String size,
  );

  @GET("/persons/{person_id}/photos")
  Future<PersonWithPhotosResponse> getPersonPhotos(
    @Path("person_id") String personId,
    @Query("skip") int skip,
    @Query("limit") int limit,
  );

  // ==========================================
  // Billing & Payments
  // ==========================================

  @GET("/payments/plans")
  Future<List<PlanResponse>> getPlans(@Query("role") String role);

  @POST("/payments/apply-coupon")
  Future<ApplyCouponResponse> applyCoupon(@Body() ApplyCouponRequest request);

  @POST("/payments/create-order")
  Future<CreateOrderResponse> createOrder(@Body() CreateOrderRequest request);

  @POST("/payments/verify")
  Future<VerifyPaymentResponse> verifyPayment(@Body() VerifyPaymentRequest request);

  @GET("/payments/usage")
  Future<ResourceUsageResponse> getResourceUsage();

  @POST("/payments/subscriptions/cancel")
  Future<SubscriptionResponse> cancelSubscription();

  @POST("/payments/subscriptions/reactivate")
  Future<SubscriptionResponse> reactivateSubscription();
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final authState = ref.watch(authProvider);
  final dio = Dio();
  if (authState.isAuthenticated && authState.accessToken != null) {
    dio.options.headers['Authorization'] = 'Bearer ${authState.accessToken}';
  }
  return ApiClient(dio);
});
