import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'models.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: "http://10.0.2.2:8000/api/v1") // Dev default targeting local machine via Android emulator
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // ==========================================
  // Authentication
  // ==========================================

  @POST("/auth/send-otp")
  Future<SendOtpResponse> sendOtp(@Body() SendOtpRequest request);

  @POST("/auth/verify-otp")
  Future<VerifyOtpResponse> verifyOtp(@Body() VerifyOtpRequest request);

  @POST("/auth/signup")
  Future<SignupResponse> signup(@Body() SignupRequest request);

  @POST("/auth/refresh")
  Future<RefreshTokenResponse> refreshToken(@Body() RefreshTokenRequest request);

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

  // ==========================================
  // Device tokens for push notifications
  // ==========================================

  @POST("/device-tokens/register")
  Future<DeviceTokenResponse> registerDeviceToken(@Body() DeviceTokenRegisterRequest request);

  @DELETE("/device-tokens/{token}")
  Future<void> unregisterDeviceToken(@Path("token") String token);
}
