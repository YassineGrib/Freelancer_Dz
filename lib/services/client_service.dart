import '../models/client_model.dart';
import 'local_database_service.dart';
import 'auth_service.dart';

class ClientService {
  static final LocalDatabaseService _db = LocalDatabaseService.instance;
  static const String _tableName = 'clients';

  // Get all clients for the current user
  static Future<List<ClientModel>> getClients() async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final clientsData = await _db.getClients(userId);
      return clientsData.map<ClientModel>((json) => ClientModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch clients: ${e.toString()}');
    }
  }

  // Alias for getClients for backward compatibility
  static Future<List<ClientModel>> getAllClients() async {
    return getClients();
  }

  // Add a new client
  static Future<ClientModel> addClient(ClientModel client) async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final clientData = client.toJson();
      clientData.remove('id'); // Remove ID to let database generate it

      final clientId = await _db.createClient(userId, clientData);

      // Get the created client
      final createdClientData = await _db.getClientById(clientId);
      if (createdClientData == null) {
        throw Exception('Failed to retrieve created client');
      }

      return ClientModel.fromJson(createdClientData);
    } catch (e) {
      throw Exception('Failed to create client: ${e.toString()}');
    }
  }

  // Update an existing client
  static Future<ClientModel> updateClient(ClientModel client) async {
    try {
      if (client.id == null) {
        throw Exception('Client ID is required for update');
      }

      final clientData = client.toJson();
      clientData.remove('id'); // Remove ID from update data

      await _db.updateClient(client.id!, clientData);

      // Get the updated client
      final updatedClientData = await _db.getClientById(client.id!);
      if (updatedClientData == null) {
        throw Exception('Failed to retrieve updated client');
      }

      return ClientModel.fromJson(updatedClientData);
    } catch (e) {
      throw Exception('Failed to update client: ${e.toString()}');
    }
  }

  // Delete a client
  static Future<void> deleteClient(String clientId) async {
    try {
      await _db.deleteClient(clientId);
    } catch (e) {
      throw Exception('Failed to delete client: ${e.toString()}');
    }
  }

  // Search clients by name, email, or phone
  static Future<List<ClientModel>> searchClients(String query) async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (query.isEmpty) {
        return getClients();
      }

      final clientsData = await _db.searchClients(userId, query);
      return clientsData.map<ClientModel>((json) => ClientModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search clients: ${e.toString()}');
    }
  }

  // Filter clients by type
  static Future<List<ClientModel>> filterClientsByType(ClientType clientType) async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final allClients = await getClients();
      return allClients.where((client) => client.clientType == clientType).toList();
    } catch (e) {
      throw Exception('Failed to filter clients: ${e.toString()}');
    }
  }

  // Get client by ID
  static Future<ClientModel?> getClientById(String clientId) async {
    try {
      final clientData = await _db.getClientById(clientId);
      return clientData != null ? ClientModel.fromJson(clientData) : null;
    } catch (e) {
      throw Exception('Failed to get client: ${e.toString()}');
    }
  }
}

