import '../models/invoice_model.dart';
import 'local_database_service.dart';
import 'local_database_extensions.dart';
import 'auth_service.dart';

class InvoiceService {
  static final LocalDatabaseService _db = LocalDatabaseService.instance;

  static String? get _userId => AuthService.currentUser?["id"];

  static Future<List<InvoiceModel>> getAllInvoices() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final invoicesData = await _db.getInvoices(_userId!);
      final invoices = <InvoiceModel>[];

      for (final invoiceData in invoicesData) {
        // Create a mutable copy of the invoice data
        final mutableInvoiceData = Map<String, dynamic>.from(invoiceData);

        final clientData = await _db.getClientById(invoiceData["client_id"]);
        if (clientData != null) {
          mutableInvoiceData["clients"] = clientData;
        }

        if (invoiceData["project_id"] != null) {
          final projectData =
              await _db.getProjectById(invoiceData["project_id"]);
          if (projectData != null) {
            mutableInvoiceData["projects"] = projectData;
          }
        }

        invoices.add(InvoiceModel.fromJson(mutableInvoiceData));
      }

      return invoices;
    } catch (e) {
      throw Exception("Failed to fetch invoices: $e");
    }
  }

  static Future<List<InvoiceModel>> getInvoicesByProject(
      String projectId) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final invoicesData = await _db.getInvoicesByProject(_userId!, projectId);
      final invoices = <InvoiceModel>[];

      for (final invoiceData in invoicesData) {
        // Create a mutable copy of the invoice data
        final mutableInvoiceData = Map<String, dynamic>.from(invoiceData);

        final clientData = await _db.getClientById(invoiceData["client_id"]);
        if (clientData != null) {
          mutableInvoiceData["clients"] = clientData;
        }

        final projectData = await _db.getProjectById(invoiceData["project_id"]);
        if (projectData != null) {
          mutableInvoiceData["projects"] = projectData;
        }

        invoices.add(InvoiceModel.fromJson(mutableInvoiceData));
      }

      return invoices;
    } catch (e) {
      throw Exception("Failed to fetch project invoices: $e");
    }
  }

  static Future<List<InvoiceModel>> getInvoicesByClient(String clientId) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final invoicesData = await _db.getInvoicesByClient(_userId!, clientId);
      final invoices = <InvoiceModel>[];

      for (final invoiceData in invoicesData) {
        // Create a mutable copy of the invoice data
        final mutableInvoiceData = Map<String, dynamic>.from(invoiceData);

        final clientData = await _db.getClientById(invoiceData["client_id"]);
        if (clientData != null) {
          mutableInvoiceData["clients"] = clientData;
        }

        if (invoiceData["project_id"] != null) {
          final projectData =
              await _db.getProjectById(invoiceData["project_id"]);
          if (projectData != null) {
            mutableInvoiceData["projects"] = projectData;
          }
        }

        invoices.add(InvoiceModel.fromJson(mutableInvoiceData));
      }

      return invoices;
    } catch (e) {
      throw Exception("Failed to fetch client invoices: $e");
    }
  }

  static Future<InvoiceModel> addInvoice(InvoiceModel invoice) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final invoiceData = invoice.toJson();
      invoiceData.remove("id");

      final invoiceId = await _db.createInvoice(_userId!, invoiceData);

      final createdInvoiceData = await _db.getInvoiceById(invoiceId);
      if (createdInvoiceData == null) {
        throw Exception("Failed to retrieve created invoice");
      }

      // Create a mutable copy of the created invoice data
      final mutableCreatedInvoiceData =
          Map<String, dynamic>.from(createdInvoiceData);

      final clientData =
          await _db.getClientById(createdInvoiceData["client_id"]);
      if (clientData != null) {
        mutableCreatedInvoiceData["clients"] = clientData;
      }

      if (createdInvoiceData["project_id"] != null) {
        final projectData =
            await _db.getProjectById(createdInvoiceData["project_id"]);
        if (projectData != null) {
          mutableCreatedInvoiceData["projects"] = projectData;
        }
      }

      return InvoiceModel.fromJson(mutableCreatedInvoiceData);
    } catch (e) {
      throw Exception("Failed to create invoice: $e");
    }
  }

  static Future<InvoiceModel> updateInvoice(InvoiceModel invoice) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      if (invoice.id == null) {
        throw Exception("Invoice ID is required for update");
      }

      final invoiceData = invoice.toJson();
      invoiceData.remove("clients");
      invoiceData.remove("projects");

      await _db.updateInvoice(invoice.id!, invoiceData);

      final updatedInvoiceData = await _db.getInvoiceById(invoice.id!);
      if (updatedInvoiceData == null) {
        throw Exception("Failed to retrieve updated invoice");
      }

      // Create a mutable copy of the updated invoice data
      final mutableUpdatedInvoiceData =
          Map<String, dynamic>.from(updatedInvoiceData);

      final clientData =
          await _db.getClientById(updatedInvoiceData["client_id"]);
      if (clientData != null) {
        mutableUpdatedInvoiceData["clients"] = clientData;
      }

      if (updatedInvoiceData["project_id"] != null) {
        final projectData =
            await _db.getProjectById(updatedInvoiceData["project_id"]);
        if (projectData != null) {
          mutableUpdatedInvoiceData["projects"] = projectData;
        }
      }

      return InvoiceModel.fromJson(mutableUpdatedInvoiceData);
    } catch (e) {
      throw Exception("Failed to update invoice: $e");
    }
  }

  static Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _db.deleteInvoice(invoiceId);
    } catch (e) {
      throw Exception("Failed to delete invoice: $e");
    }
  }

  static Future<InvoiceModel> updateInvoiceStatus(
      String invoiceId, InvoiceStatus status) async {
    try {
      final invoiceData = await _db.getInvoiceById(invoiceId);
      if (invoiceData == null) {
        throw Exception("Invoice not found");
      }

      // Create a mutable copy of the invoice data
      final mutableInvoiceData = Map<String, dynamic>.from(invoiceData);

      mutableInvoiceData["status"] = status.name;
      await _db.updateInvoice(invoiceId, mutableInvoiceData);

      final clientData = await _db.getClientById(invoiceData["client_id"]);
      if (clientData != null) {
        mutableInvoiceData["clients"] = clientData;
      }

      if (invoiceData["project_id"] != null) {
        final projectData = await _db.getProjectById(invoiceData["project_id"]);
        if (projectData != null) {
          mutableInvoiceData["projects"] = projectData;
        }
      }

      return InvoiceModel.fromJson(mutableInvoiceData);
    } catch (e) {
      throw Exception("Failed to update invoice status: $e");
    }
  }

  static Future<String> generateInvoiceNumber() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final invoices = await getAllInvoices();
      final currentYear = DateTime.now().year;
      final yearInvoices = invoices
          .where((invoice) => invoice.issueDate.year == currentYear)
          .toList();

      final nextNumber = yearInvoices.length + 1;
      return "INV-$currentYear-${nextNumber.toString().padLeft(4, "0")}";
    } catch (e) {
      return "INV-${DateTime.now().year}-0001";
    }
  }

  static Future<double> getTotalRevenue() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final invoices = await getAllInvoices();
      double total = 0.0;

      for (final invoice in invoices) {
        if (invoice.status == InvoiceStatus.paid) {
          total += invoice.total;
        }
      }

      return total;
    } catch (e) {
      throw Exception("Failed to calculate total revenue: $e");
    }
  }

  static Future<double> getTotalOutstanding() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final invoices = await getAllInvoices();
      double total = 0.0;

      for (final invoice in invoices) {
        if (invoice.status == InvoiceStatus.sent ||
            invoice.status == InvoiceStatus.overdue) {
          total += invoice.total;
        }
      }

      return total;
    } catch (e) {
      throw Exception("Failed to calculate total outstanding: $e");
    }
  }
}
