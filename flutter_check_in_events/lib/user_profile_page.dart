import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatefulWidget {
  final String idUsu;

  const UserProfilePage({Key? key, required this.idUsu}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<User?> _userInfo;

  @override
  void initState() {
    super.initState();
    _userInfo =
        _fetchUserInfo(); // Busca as informações do usuário ao inicializar
  }

  Future<User?> _fetchUserInfo() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('Usuario').doc(widget.idUsu).get();
      if (doc.exists) {
        return User.fromFirestore(
            doc); // Retorna um objeto User se o documento existir
      } else {
        return null; // Retorna null se o documento não existir
      }
    } catch (e) {
      print("Erro ao buscar informações do usuário: $e");
      return null; // Retorna null em caso de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 40, // Ajuste a posição conforme necessário
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white), // Ícone de voltar
              onPressed: () {
                Navigator.pop(context); // Navega de volta à página anterior
              },
            ),
          ),
          FutureBuilder<User?>(
            future: _userInfo,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text("Erro ao carregar perfil",
                        style: TextStyle(color: Colors.white)));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                    child: Text("Usuário não encontrado",
                        style: TextStyle(color: Colors.white)));
              } else {
                User user = snapshot.data!;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(user.profilePictureUrl),
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Telefone: ${user.phone}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Data de Nascimento: ${user.dataNasc}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Ação de editar perfil
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            child: Text('Editar Perfil',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// Modelo User
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String dataNasc;
  final String profilePictureUrl; // Adicionando URL da imagem do perfil

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.dataNasc,
    required this.profilePictureUrl, // Adicionando parâmetro
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['NomeUsu'] ?? 'Nome não disponível', // Valor padrão seguro
      email: data['EmailUsu'] ?? 'Email não disponível', // Valor padrão seguro
      phone: data['CPFUsu'] ??
          'CPF não disponível', // Verifique se é o campo correto
      dataNasc:
          data['DataNascimentoUsu'] ?? 'Data de nascimento não disponível',
      profilePictureUrl: data['profilePictureUrl'] ?? '', // URL padrão seguro
    );
  }
}
