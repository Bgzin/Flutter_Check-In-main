import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_check_in_events/events_list.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MyEventDetailsScreen extends StatefulWidget {
  final Event event;
  final String partiId;

  const MyEventDetailsScreen({
    Key? key,
    required this.event,
    required this.partiId,
  }) : super(key: key);

  @override
  State<MyEventDetailsScreen> createState() => _MyEventDetailsScreenState();
}

class _MyEventDetailsScreenState extends State<MyEventDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isCheckingIn = false;
  bool _isInRange = false;
  late LatLng eventLocation;
  List<int> ratings = [];

  @override
  void initState() {
    super.initState();
    eventLocation = _parseLocation(widget.event.local);
    _fetchRatings();
  }

  Future<void> _getUserLocationAndCheckIn() async {
    if (!await _checkLocationPermissions()) return;

    setState(() => _isCheckingIn = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng userLocation = LatLng(position.latitude, position.longitude);
      double distanceInMeters = _calculateDistance(userLocation, eventLocation);

      setState(() => _isInRange = distanceInMeters <= 50);

      if (_isInRange) {
        await _createCheckIn(widget.event.id, userLocation);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Check-in realizado com sucesso!")),

        );
        await _waitForUserToExitRadius(userLocation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Você está a ${distanceInMeters.toStringAsFixed(2)} metros do evento. Aproximar-se!")),
        );
      }
    } catch (e) {
      debugPrint("Erro ao obter localização do usuário: $e");
    } finally {
      setState(() => _isCheckingIn = false);
    }
  }

  Future<void> _waitForUserToExitRadius(LatLng initialLocation) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng userLocation = LatLng(position.latitude, position.longitude);
      double distanceInMeters = _calculateDistance(userLocation, eventLocation);

      setState(() => _isInRange = distanceInMeters <= 50);

      if (!_isInRange) {
        _showRatingDialog();
        break;
      }
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Avalie o Evento"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: ratings.contains(index + 1)
                          ? Colors.yellow
                          : Colors.grey,
                    ),
                    onPressed: () {
                      _saveRating(index + 1);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Text("Avaliações:"),
              ...ratings
                  .map((rating) => Text("⭐ ${rating.toString()} estrelas")),
            ],
          ),
        );
      },
    );
  }

  void _saveRating(int rating) async {
    await _firestore
        .collection('Evento')
        .doc(widget.event.id)
        .collection('Avaliacoes')
        .add({'estrelas': rating});
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    final snapshot = await _firestore
        .collection('Evento')
        .doc(widget.event.id)
        .collection('Avaliacoes')
        .get();
    ratings = snapshot.docs.map((doc) => doc['estrelas'] as int).toList();
    setState(() {});
  }

  LatLng _parseLocation(String locationString) {
    List<String> parts = locationString.split(',');
    return LatLng(double.parse(parts[0].trim()), double.parse(parts[1].trim()));
  }

  Future<void> _createCheckIn(String eventId, LatLng userLocation) async {
    await _firestore
        .collection('Evento')
        .doc(eventId)
        .collection('Check-in')
        .add({
      'HorarioCheck': DateTime.now().toString(),
      'StatusCheck': 'Registrado',
      'LocalizacaoAtualCheck':
          '${userLocation.latitude}, ${userLocation.longitude}',
      'idUsu': widget.partiId,
    });
  }

  Future<bool> _checkLocationPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Serviço de localização desativado!")));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permissão de localização negada!")));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Permissão de localização permanentemente negada!")));
      return false;
    }

    return true;
  }

  double _calculateDistance(LatLng userLocation, LatLng eventLocation) {
    final Distance distance = Distance();
    return distance(userLocation, eventLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.nome, style: const TextStyle(fontSize: 24)),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,  // Cor sólida para o fundo
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Remover a exibição de imagem e substituir por fundo sólido
                  const SizedBox(height: 16),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nome: ${widget.event.nome}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 8),
                          Text('Descrição: ${widget.event.descricao}',
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Data e Hora: ${widget.event.data}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Localização: ${widget.event.local}',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Status: ${widget.event.status}',
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _isCheckingIn ? null : _getUserLocationAndCheckIn,
                icon: const Icon(Icons.check_circle),
                label: Text(_isCheckingIn ? "Check-out" : "Check-in"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isInRange ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
