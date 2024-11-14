import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_check_in_events/events_details.dart';
import 'package:flutter_check_in_events/user_profile_page.dart';

class MyListEventsPage extends StatefulWidget {
  final String idUsu;

  const MyListEventsPage({super.key, required this.idUsu});

  @override
  State<MyListEventsPage> createState() => _MyListEventsPageState();
}

class _MyListEventsPageState extends State<MyListEventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<Event>> _events;

  @override
  void initState() {
    super.initState();
    _events = _fetchEvents(); // Busca os eventos ao inicializar
  }

  /* Método para rodar */
  Future<List<Event>> _fetchEvents() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Evento').get();
      return snapshot.docs.map((doc) {
        return Event.fromFirestore(
            doc); // Cria um objeto Event a partir do documento
      }).toList();
    } catch (e) {
      print("Erro ao buscar eventos: $e");
      return []; // Retorna uma lista vazia em caso de erro
    }
  }

  /* Visual */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error);
              },
            ),
            const SizedBox(width: 25),
            const Text('Connect'),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle_sharp,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(idUsu: widget.idUsu),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/banner.png',
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: FutureBuilder<List<Event>>(
                future: _events,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text("Erro ao carregar eventos");
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("Nenhum evento encontrado");
                  } else {
                    return Expanded(
                      // Adicionando Expanded aqui
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        children: snapshot.data!.map((event) {
                          return EventCard(
                            image: 'assets/event_default.png',
                            event: event,
                            idUsu: widget.idUsu,
                          );
                        }).toList(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* Visual do CARD */
class EventCard extends StatelessWidget {
  final String image;
  final Event event;
  final String idUsu;

  const EventCard({
    required this.image,
    required this.event,
    required this.idUsu,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Expanded(
            child: Image.network(
              event.image,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              event.nome,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyEventDetailsScreen(
                    event: event, // O evento deve ser uma instância de Event
                    partiId:
                        idUsu, // Certifique-se de que idUsu está corretamente definido
                  ),
                ),
              );
            },
            child: const Text('Ver Detalhes'),
          ),
        ],
      ),
    );
  }
}

// Modelo Event
class Event {
  final String id;
  final String nome;
  final String descricao;
  final String data;
  final String local;
  final String status;
  final String image;
  final int idadMinima;

  Event({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.data,
    required this.local,
    required this.status,
    required this.image,
    required this.idadMinima,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      nome: data['NomeEvent'] ?? 'Evento sem nome',
      descricao: data['DescricaoEvent'] ?? 'Sem descrição',
      data: data['DataHoraEvent'] ?? 'Data não disponível',
      local: data['LocalizacaoEvent'] ?? 'Local não especificado',
      status: data['StatusEvent'] ?? 'Status não disponível',
      image: data['imgEvent'] ?? 'Status não disponível',
      idadMinima: int.tryParse(doc['idadMinima'].toString()) ?? 0,
    );
  }
}
