part of 'profile_cubit.dart';

@immutable
abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// [ProfileCheckingAvailability] indicates that whether or not the user
/// has a profile is unknown and is being checked.
class ProfileCheckingAvailability extends ProfileState {}

/// [ProfileUnavailable] is a superclass state that indicates that
/// the user has a profile that can/has been logged into.
abstract class ProfileAvailable extends ProfileState {}

/// [ProfileUnavailable] is a superclass state that indicates that
/// the user has no profile to log into.
abstract class ProfileUnavailable extends ProfileState {}

class ProfilePromptLogIn extends ProfileAvailable {}

class ProfileLoggingIn extends ProfileAvailable {}

class ProfileLoggedIn extends ProfileAvailable {
  final String? username;
  final String password;

  final Wallet wallet;

  final String walletAddress;

  final ProfileSource profileSource;

  /// The user's wallet balance in winston.
  final BigInt walletBalance;

  final SecretKey cipherKey;
  final bool useTurbo;
  final arconnect = ArConnectService();

  ProfileLoggedIn({
    required this.username,
    required this.password,
    required this.wallet,
    required this.walletAddress,
    required this.profileSource,
    required this.walletBalance,
    required this.cipherKey,
    required this.useTurbo,
  });

  ProfileLoggedIn copyWith({
    String? username,
    String? password,
    Wallet? wallet,
    String? walletAddress,
    ProfileSource? profileSource,
    BigInt? walletBalance,
    SecretKey? cipherKey,
    bool? useTurbo,
  }) =>
      ProfileLoggedIn(
        username: username ?? this.username,
        password: password ?? this.password,
        wallet: wallet ?? this.wallet,
        walletAddress: walletAddress ?? this.walletAddress,
        profileSource: profileSource ?? this.profileSource,
        walletBalance: walletBalance ?? this.walletBalance,
        cipherKey: cipherKey ?? this.cipherKey,
        useTurbo: useTurbo ?? this.useTurbo,
      );

  bool hasMinimumBalanceForUpload({required BigInt minimumWalletBalance}) =>
      walletBalance > minimumWalletBalance;

  bool canUpload({required BigInt minimumWalletBalance}) =>
      hasMinimumBalanceForUpload(minimumWalletBalance: minimumWalletBalance) ||
      useTurbo;

  @override
  List<Object?> get props => [
        username,
        password,
        wallet,
        walletAddress,
        profileSource,
        walletBalance,
        cipherKey,
      ];
}

class ProfilePromptAdd extends ProfileUnavailable {}

class ProfileLoggingOut extends ProfileUnavailable {}
