# Arquitetura Feature-Based Simplificada - Coisa Rápida

## 📋 Contexto

Backend (NestJS) contém **todas as regras de negócio**. Frontend Flutter é apenas **apresentação e orquestração**, sem duplicação de lógica e **sem camada de domain**.

---

## 🏗️ ESTRUTURA FEATURE-BASED (SEM DOMAIN)

```
lib/
├── core/                           # Configurações globais
│   ├── config/
│   │   └── app_config.dart        # Inicializações
│   ├── constants/
│   │   └── app_routes_constants.dart
│   ├── exceptions/
│   │   └── app_exception.dart     # Exceções personalizadas
│   ├── services/
│   │   └── logger_service.dart
│   └── theme/
│       └── app_theme.dart
│
├── shared/                         # Compartilhado entre features
│   ├── models/                     # DTOs da API (reutilizáveis)
│   │   └── user_model.dart
│   ├── repositories/               # Lógica + transformação
│   │   └── user_repository.dart
│   ├── services/
│   │   └── api_client.dart        # HttpClient (Retrofit)
│   ├── providers/                  # Providers globais
│   │   ├── router_provider.dart
│   │   ├── theme_provider.dart
│   │   └── shared_preference_provider.dart
│   └── widgets/                    # Componentes reutilizáveis
│       └── app_loader.dart
│
└── features/                       # Features agrupadas
    ├── splash/
    │   ├── data/
    │   │   ├── datasources/       # Chamadas HTTP da feature
    │   │   │   └── splash_datasource.dart
    │   │   └── models/            # DTOs específicos
    │   │       └── splash_model.dart
    │   └── presentation/
    │       ├── providers/         # Estados (Riverpod)
    │       │   └── splash_provider.dart
    │       ├── screens/
    │       │   └── splash_screen.dart
    │       └── widgets/           # Widgets específicos
    │           └── splash_background.dart
    │
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── auth_datasource.dart
    │   │   └── models/
    │   │       ├── login_request_model.dart
    │   │       └── user_model.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── auth_provider.dart
    │       ├── screens/
    │       │   ├── login_screen.dart
    │       │   └── register_screen.dart
    │       └── widgets/
    │           ├── login_form.dart
    │           └── password_field.dart
    │
    ├── home/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── home_datasource.dart
    │   │   └── models/
    │   │       └── item_model.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── items_provider.dart
    │       ├── screens/
    │       │   └── home_screen.dart
    │       └── widgets/
    │           └── item_card.dart
    │
    └── [outras features...]
```

---

## 💡 PADRÃO: SEM DOMAIN

### ❌ ANTES (com Domain - complexo)

```dart
// domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String nome;
  final String email;
}

// domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<UserEntity> getUser(String id);
}

// data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  @override
  Future<UserEntity> getUser(String id) async {
    final model = await apiClient.getUser(id);
    return model.toEntity(); // Model -> Entity
  }
}
```

### ✅ AGORA (sem Domain - direto)

```dart
// shared/models/user_model.dart
@JsonSerializable()
class UserModel {
  final String id;
  final String nome;
  final String email;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

// shared/repositories/user_repository.dart
class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<UserModel> getUser(String id) async {
    try {
      return await _apiClient.getUser(id);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }
}

// presentation/providers/user_provider.dart
final userProvider = FutureProvider.family<UserModel, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUser(userId);
});
```

**Economia:**

- ❌ Sem `entity` (Entity = Model)
- ❌ Sem `domain/repositories` (Repository = implementação direto)
- ✅ Direto Model → Provider → Screen

---

## 📝 EXEMPLO PRÁTICO: Feature Auth

### 1️⃣ Model (API DTO)

```dart
// features/auth/data/models/user_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String nome;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'created_at')
  final String createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.nome,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable()
class LoginRequestModel {
  final String email;
  final String password;

  LoginRequestModel({
    required this.email,
    required this.password,
  });

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestModelToJson(this);
}

@JsonSerializable()
class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);
}
```

### 2️⃣ DataSource (HTTP)

```dart
// features/auth/data/datasources/auth_datasource.dart
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';

part 'auth_datasource.g.dart';

@RestApi(baseUrl: 'https://api.coisarapida.com/api')
abstract class AuthDataSource {
  factory AuthDataSource(Dio dio, {String? baseUrl}) = _AuthDataSource;

  @POST('/auth/login')
  Future<AuthResponseModel> login(@Body() LoginRequestModel request);

  @POST('/auth/register')
  Future<AuthResponseModel> register(@Body() RegisterRequestModel request);

  @POST('/auth/refresh')
  Future<AuthResponseModel> refresh(@Body() RefreshTokenModel request);

  @GET('/auth/me')
  Future<UserModel> getCurrentUser();

  @POST('/auth/logout')
  Future<void> logout();
}
```

### 3️⃣ Repository (Lógica + Transformação)

```dart
// shared/repositories/auth_repository.dart
import 'package:coisa_rapida/core/exceptions/app_exception.dart';
import 'package:coisa_rapida/core/services/logger_service.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../features/auth/data/datasources/auth_datasource.dart';

class AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepository(this._dataSource);

  /// Login e retorna os dados transformados
  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dataSource.login(
        LoginRequestModel(email: email, password: password),
      );

      // Aqui você transforma/processa os dados se necessário
      logger.i('Login bem-sucedido: ${response.user.email}');

      return (
        token: response.accessToken,
        user: response.user,
      );
    } on DioException catch (e) {
      logger.e('Erro ao fazer login', error: e);
      throw _mapDioException(e);
    } catch (e) {
      logger.e('Erro desconhecido no login', error: e);
      throw UnknownException(message: 'Erro ao fazer login');
    }
  }

  Future<UserModel> getMe() async {
    try {
      return await _dataSource.getCurrentUser();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dataSource.logout();
      logger.i('Logout realizado');
    } on DioException catch (e) {
      logger.e('Erro ao fazer logout', error: e);
      throw _mapDioException(e);
    }
  }

  AppException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return NetworkException(message: 'Conexão expirou');
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(message: 'Sem internet');
    }

    final statusCode = e.response?.statusCode ?? 0;
    final message = e.response?.data['message'] ?? 'Erro desconhecido';

    if (statusCode >= 400 && statusCode < 500) {
      return ClientException(
        message: message,
        statusCode: statusCode,
      );
    }

    return ServerException(
      message: message,
      statusCode: statusCode,
    );
  }
}
```

### 4️⃣ Provider (State Management)

```dart
// features/auth/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/repositories/auth_repository.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/shared_preference_provider.dart';
import '../../../auth/data/datasources/auth_datasource.dart';

// DI Providers
final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.coisarapida.com/api',
    connectTimeout: const Duration(seconds: 30),
  ));
  return dio;
});

final authDataSourceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthDataSource(dio);
});

final authRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepository(dataSource);
});

// Feature Providers
final currentUserProvider = FutureProvider<UserModel>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return await repository.getMe();
});

final loginProvider = FutureProvider.family<
    ({String token, UserModel user}),
    ({String email, String password})>((ref, credentials) async {
  final repository = ref.watch(authRepositoryProvider);
  return await repository.login(
    email: credentials.email,
    password: credentials.password,
  );
});

final logoutProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  await repository.logout();
  // Limpar token
  final prefs = ref.read(sharedPrefsProvider);
  await prefs.remove('auth_token');
});
```

### 5️⃣ Screen (UI)

```dart
// features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                // Consumir o provider de login
                final result = await ref.read(
                  loginProvider(
                    (
                      email: emailController.text,
                      password: passwordController.text,
                    ),
                  ).future,
                );

                // Salvar token
                final prefs = ref.read(sharedPrefsProvider);
                await prefs.setString('auth_token', result.token);

                // Navegar para home
                if (context.mounted) {
                  context.go('/home');
                }
              },
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎯 DIFERENÇAS NA ESTRUTURA

| Aspecto                 | Com Domain | Sem Domain |
| ----------------------- | ---------- | ---------- |
| **Camadas**             | 4          | 3          |
| **Entity file**         | ✅         | ❌         |
| **Repository abstract** | ✅         | ❌         |
| **Arquivo linhas**      | +50%       | -50%       |
| **Complexidade**        | Alta       | Baixa      |
| **Model = Entity**      | ❌         | ✅         |
| **Direto API→Screen**   | ❌         | ✅         |

---

## ⚡ FLUXO DE DADOS SIMPLIFICADO

```
Screen
  ↓
ref.watch(provider)
  ↓
Riverpod Provider (FutureProvider/StateNotifierProvider)
  ↓
Repository.metodo()
  ↓
DataSource.httpCall()
  ↓
ApiClient (Retrofit)
  ↓
Backend API
```

**Exemplo prático:**

```dart
// Screen consome direto
final userAsync = ref.watch(userProvider('123'));

// Provider chama repository
final userProvider = FutureProvider.family<UserModel, String>((ref, id) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUser(id); // Repository busca + transforma
});

// Repository chama DataSource
class UserRepository {
  Future<UserModel> getUser(String id) {
    return _dataSource.getUser(id); // Só retorna o Model
  }
}

// DataSource faz HTTP
class UserDataSource {
  @GET('/users/{id}')
  Future<UserModel> getUser(@Path('id') String id);
}
```

---

## 📋 CHECKLIST POR FEATURE

- [ ] Criar models (data/models/)
- [ ] Criar datasource (data/datasources/)
- [ ] Criar repository (shared/repositories/)
- [ ] Criar providers (presentation/providers/)
- [ ] Criar screens (presentation/screens/)
- [ ] Rodar `flutter pub run build_runner watch`
- [ ] Testar fluxo UI → Provider → Repository → API
- [ ] Implementar error handling

---

## 🚀 PRÓXIMAS FEATURES A IMPLEMENTAR

Com essa estrutura pronta, você pode facilmente adicionar:

1. **Auth Feature** ✅
2. **Home/Items Feature**
3. **User Profile Feature**
4. **Etc...**

Cada uma segue o mesmo padrão: Model → DataSource → Repository → Provider → Screen

Muito mais simples! 🎯

## 📋 Contexto

Seu backend (NestJS) já contém **todas as regras de negócio**, validações e lógica de domínio. O frontend Flutter será **apenas apresentação e orquestração de chamadas à API**, sem duplicação de lógica.

---

## 🏗️ ARQUITETURA APLICADA NO PROJETO

Como o backend cuida da lógica, implementamos uma arquitetura simplificada:

```
lib/
├── main.dart                          # Ponto de entrada
│
├── config/                            # Configurações da aplicação
│   └── app_config.dart               # Inicializações globais
│
├── shared/                            # Código compartilhado
│   ├── constants/
│   │   └── app_routes_constants.dart
│   ├── exceptions/
│   │   └── app_exception.dart        # Exceções personalizadas
│   ├── services/
│   │   └── logger_service.dart       # Logger global
│   ├── providers/
│   │   ├── router_provider.dart      # Navegação (GoRouter)
│   │   ├── theme_provider.dart       # Tema da aplicação
│   │   └── shared_preference_provider.dart  # Acesso ao SharedPreferences
│   ├── app_theme.dart                # Tema Material
│   └── constants/
│       └── app_routes_constants.dart # Rotas da aplicação
│
├── presentation/                      # UI Layer (Telas e Widgets)
│   ├── providers/                     # Riverpod providers específicos de features
│   │   └── *_provider.dart          # Ex: items_provider.dart
│   ├── screens/                       # Telas (Pages)
│   │   └── splash/
│   │       └── splash_screen.dart    # Tela de splashscreen
│   └── widgets/                       # Componentes reutilizáveis
│       └── *.dart
│
├── domain/                            # Domain Layer (Tipos simples)
│   ├── entities/                      # Entidades de negócio
│   │   └── *.dart                    # Ex: user_entity.dart, item_entity.dart
│   └── repositories/                  # Contratos (Interfaces)
│       └── *.dart                    # Ex: user_repository.dart
│
├── data/                              # Data Layer (Acesso a dados)
│   ├── datasources/
│   │   └── api/
│   │       └── api_client.dart       # Cliente HTTP (Retrofit)
│   ├── models/                        # DTOs (Data Transfer Objects)
│   │   └── *.dart                    # Ex: user_model.dart
│   └── repositories/                  # Implementações de repositories
│       └── *.dart                    # Ex: user_repository_impl.dart
│
└── splash_page.dart                   # (Será movida para presentation/screens/splash)
```

---

## 🎯 FLUXO DE DADOS

```
UI (Screen/Widget)
    ↓
Riverpod Provider (FutureProvider/StateNotifier)
    ↓
Repository (Contrato)
    ↓
Repository Implementation
    ↓
ApiClient (HTTP)
    ↓
Backend NestJS
```

**Exemplo prático:**

```dart
// 1. Backend retorna dados
// 2. ApiClient converte para Model
// 3. Repository converte Model → Entity
// 4. Provider expõe Entity para UI
// 5. Widget consome via Riverpod
```

---

## 📝 PADRÃO DE IMPLEMENTAÇÃO

### 1️⃣ Domain - Entidades (Tipos simples)

```dart
// domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String nome;
  final String email;
  final String? avatarUrl;

  UserEntity({
    required this.id,
    required this.nome,
    required this.email,
    this.avatarUrl,
  });
}
```

### 2️⃣ Domain - Repository (Contrato)

```dart
// domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<UserEntity> getUser(String id);
  Future<List<UserEntity>> getAllUsers({int page = 1, int limit = 10});
  Future<UserEntity> createUser(CreateUserRequest request);
  Future<void> deleteUser(String id);
}
```

### 3️⃣ Data - Model (DTO com JSON)

```dart
// data/models/user_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String nome;
  final String email;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Converte Model para Entity
  UserEntity toEntity() => UserEntity(
    id: id,
    nome: nome,
    email: email,
    avatarUrl: avatarUrl,
  );
}
```

### 4️⃣ Data - ApiClient (HTTP)

```dart
// data/datasources/api/api_client.dart
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../../models/user_model.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: 'https://api.coisarapida.com/api')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  @GET('/users/{id}')
  Future<UserModel> getUser(@Path('id') String id);

  @GET('/users')
  Future<List<UserModel>> getAllUsers(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST('/users')
  Future<UserModel> createUser(@Body() CreateUserRequest request);

  @DELETE('/users/{id}')
  Future<void> deleteUser(@Path('id') String id);
}
```

### 5️⃣ Data - Repository Implementation

```dart
// data/repositories/user_repository_impl.dart
import 'package:coisa_rapida/shared/exceptions/app_exception.dart';
import 'package:coisa_rapida/shared/services/logger_service.dart';

class UserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient;

  UserRepositoryImpl(this._apiClient);

  @override
  Future<UserEntity> getUser(String id) async {
    try {
      final model = await _apiClient.getUser(id);
      return model.toEntity();
    } on DioException catch (e) {
      logger.e('Erro ao buscar usuário', error: e);
      throw _mapDioException(e);
    } catch (e) {
      logger.e('Erro desconhecido', error: e);
      throw UnknownException(message: 'Erro ao buscar usuário');
    }
  }

  @override
  Future<List<UserEntity>> getAllUsers({int page = 1, int limit = 10}) async {
    try {
      final models = await _apiClient.getAllUsers(page, limit);
      return models.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      logger.e('Erro ao listar usuários', error: e);
      throw _mapDioException(e);
    } catch (e) {
      logger.e('Erro desconhecido', error: e);
      throw UnknownException(message: 'Erro ao listar usuários');
    }
  }

  @override
  Future<UserEntity> createUser(CreateUserRequest request) async {
    try {
      final model = await _apiClient.createUser(request);
      return model.toEntity();
    } on DioException catch (e) {
      logger.e('Erro ao criar usuário', error: e);
      throw _mapDioException(e);
    } catch (e) {
      logger.e('Erro desconhecido', error: e);
      throw UnknownException(message: 'Erro ao criar usuário');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _apiClient.deleteUser(id);
    } on DioException catch (e) {
      logger.e('Erro ao deletar usuário', error: e);
      throw _mapDioException(e);
    } catch (e) {
      logger.e('Erro desconhecido', error: e);
      throw UnknownException(message: 'Erro ao deletar usuário');
    }
  }

  /// Mapeia exceções Dio para AppException
  AppException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(message: 'Conexão expirou');
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(message: 'Sem conexão com a internet');
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode ?? 0;
      final message = e.response?.data['message'] ?? 'Erro desconhecido';

      if (statusCode >= 400 && statusCode < 500) {
        return ClientException(
          message: message,
          statusCode: statusCode,
        );
      }

      if (statusCode >= 500) {
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
      }
    }

    return NetworkException(message: 'Erro de rede desconhecido');
  }
}
```

### 6️⃣ Presentation - Providers Riverpod

```dart
// presentation/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisa_rapida/data/datasources/api/api_client.dart';
import 'package:coisa_rapida/data/repositories/user_repository_impl.dart';

// DI Providers (injeção de dependência)
final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.coisarapida.com/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  return dio;
});

final apiClientProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

final userRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepositoryImpl(apiClient);
});

// Feature Providers
final userDetailProvider = FutureProvider.family<UserEntity, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUser(userId);
});

final usersListProvider = StateNotifierProvider<UsersNotifier, AsyncValue<List<UserEntity>>>((ref) {
  return UsersNotifier(ref.watch(userRepositoryProvider));
});

class UsersNotifier extends StateNotifier<AsyncValue<List<UserEntity>>> {
  final UserRepository _repository;
  int _currentPage = 1;
  List<UserEntity> _allUsers = [];
  bool _hasMore = true;

  UsersNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    _currentPage = 1;
    _allUsers = [];
    _hasMore = true;
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    state = await AsyncValue.guard(() async {
      final users = await _repository.getAllUsers(
        page: _currentPage,
        limit: 10,
      );

      if (users.isEmpty) {
        _hasMore = false;
      } else {
        _allUsers.addAll(users);
        _currentPage++;
      }

      return _allUsers;
    });
  }

  Future<void> loadMore() async {
    if (_hasMore && state.hasValue) {
      await _loadUsers();
    }
  }

  Future<void> refresh() async {
    await _loadInitial();
  }
}
```

### 7️⃣ Presentation - Tela (Screen)

```dart
// presentation/screens/users/users_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(usersListProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) => users.isEmpty
            ? const Center(child: Text('Nenhum usuário'))
            : ListView.builder(
                itemCount: users.length + 1,
                itemBuilder: (context, index) {
                  if (index == users.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(usersListProvider.notifier).loadMore();
                        },
                        child: const Text('Carregar mais'),
                      ),
                    );
                  }

                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user.nome),
                    subtitle: Text(user.email),
                    onTap: () {
                      // Navegar para detalhes
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(usersListProvider);
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🚀 STACK ATUAL DO PROJETO

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Networking
  dio: ^5.3.1
  retrofit: ^4.0.0
  json_annotation: ^4.8.1

  # Navigation
  go_router: ^17.0.1

  # Local Storage
  shared_preferences: ^2.3.2

  # UI
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.5.4
  riverpod_generator: ^2.6.1
  retrofit_generator: ^7.0.0
  json_serializable: ^6.8.0
```

---

## 📋 PRÓXIMOS PASSOS

1. **Adicionar Dio com Interceptors:**

   ```bash
   flutter pub add dio
   ```

2. **Adicionar Retrofit (já têm build_runner):**

   ```bash
   flutter pub add retrofit
   flutter pub add dev:retrofit_generator
   flutter pub add dev:json_serializable
   ```

3. **Criar primeira Feature (Users):**

   - [ ] `domain/entities/user_entity.dart`
   - [ ] `domain/repositories/user_repository.dart`
   - [ ] `data/models/user_model.dart`
   - [ ] `data/datasources/api/api_client.dart`
   - [ ] `data/repositories/user_repository_impl.dart`
   - [ ] `presentation/providers/user_provider.dart`
   - [ ] `presentation/screens/users_list_screen.dart`

4. **Rodar build_runner:**
   ```bash
   flutter pub run build_runner watch
   ```

---

## 🎯 REGRA DE OURO

**Se a lógica já existe no backend, não coloque no frontend!**

| Operação           | Backend | Frontend |
| ------------------ | ------- | -------- |
| Validação de dados | ✅      | ❌       |
| Regras de negócio  | ✅      | ❌       |
| Autenticação       | ✅      | ⚙️\*     |
| Cache de dados     | -       | ✅       |
| Transformação UI   | -       | ✅       |

\*⚙️ = Apenas armazenar token localmente

---

## 📝 CHECKLIST DE FEATURE

- [ ] Entity criada (domain/entities/)
- [ ] Repository abstrato criado (domain/repositories/)
- [ ] Model criado com @JsonSerializable (data/models/)
- [ ] ApiClient atualizado (data/datasources/api/)
- [ ] Repository Implementation criada (data/repositories/)
- [ ] Providers criados (presentation/providers/)
- [ ] Tela criada (presentation/screens/)
- [ ] build_runner executado
- [ ] Erro handling implementado
- [ ] Testes do repository criados

---

## 🔗 RECURSOS

- [Riverpod Docs](https://riverpod.dev)
- [GoRouter Docs](https://pub.dev/packages/go_router)
- [Retrofit Docs](https://pub.dev/packages/retrofit)
- [Flutter Architecture](https://codewithandrea.com/articles/flutter-state-management-riverpod/)
