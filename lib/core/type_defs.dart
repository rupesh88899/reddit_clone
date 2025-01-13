import 'package:fpdart/fpdart.dart';
import 'package:reddit_clone/core/failure.dart';

// typedef helps in to define type
//ression to use this is that now we have only one class for failure which is in failure.dart
typedef FutureEither<T> = Future<Either<Failure, T>>;

// through this our success is void means can return any type of thing
typedef FutureVoid = FutureEither<void>;
