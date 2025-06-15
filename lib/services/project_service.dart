import '../models/project_model.dart';
import 'local_database_service.dart';
import 'auth_service.dart';

class ProjectService {
  static final LocalDatabaseService _db = LocalDatabaseService.instance;

  // Get current user ID
  static String? get _userId => AuthService.currentUser?['id'];

  // Create a new project
  static Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final projectData = project.toJson();
      projectData.remove('id'); // Remove ID to let database generate it
      projectData.remove('clients'); // Remove client data from creation

      final projectId = await _db.createProject(_userId!, projectData);

      // Return the project with the generated ID
      return project.copyWith(id: projectId);
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // Get all projects for the current user
  static Future<List<ProjectModel>> getAllProjects() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final projectsData = await _db.getProjects(_userId!);
      final projects = <ProjectModel>[];

      for (final projectData in projectsData) {
        try {
          // Create a mutable copy of the project data
          final mutableProjectData = Map<String, dynamic>.from(projectData);

          // Get client data for each project
          final clientData = await _db.getClientById(projectData['client_id']);
          if (clientData != null) {
            mutableProjectData['clients'] = clientData;
          }

          projects.add(ProjectModel.fromJson(mutableProjectData));
        } catch (e) {
          print('Error loading client for project ${projectData['id']}: $e');
          // Continue without client data if client loading fails
          projects.add(ProjectModel.fromJson(projectData));
        }
      }

      return projects;
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  // Get projects by client ID
  static Future<List<ProjectModel>> getProjectsByClient(String clientId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final projectsData = await _db.getProjectsByClient(_userId!, clientId);
      final projects = <ProjectModel>[];

      for (final projectData in projectsData) {
        // Create a mutable copy of the project data
        final mutableProjectData = Map<String, dynamic>.from(projectData);

        // Get client data for each project
        final clientData = await _db.getClientById(projectData['client_id']);
        if (clientData != null) {
          mutableProjectData['clients'] = clientData;
        }
        projects.add(ProjectModel.fromJson(mutableProjectData));
      }

      return projects;
    } catch (e) {
      throw Exception('Failed to fetch client projects: $e');
    }
  }

  // Get project by ID
  static Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final projectData = await _db.getProjectById(projectId);
      if (projectData == null) return null;

      // Create a mutable copy of the project data
      final mutableProjectData = Map<String, dynamic>.from(projectData);

      // Get client data
      final clientData = await _db.getClientById(projectData['client_id']);
      if (clientData != null) {
        mutableProjectData['clients'] = clientData;
      }

      return ProjectModel.fromJson(mutableProjectData);
    } catch (e) {
      throw Exception('Failed to fetch project: $e');
    }
  }

  // Update project
  static Future<ProjectModel> updateProject(ProjectModel project) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      if (project.id == null) {
        throw Exception('Project ID is required for update');
      }

      final projectData = project.toJson();
      projectData.remove('clients'); // Remove client data from update

      await _db.updateProject(project.id!, projectData);

      // Get the updated project with client data
      final updatedProject = await getProjectById(project.id!);
      if (updatedProject == null) {
        throw Exception('Failed to retrieve updated project');
      }

      return updatedProject;
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  // Delete project
  static Future<void> deleteProject(String projectId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      await _db.deleteProject(projectId);
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  // Search projects
  static Future<List<ProjectModel>> searchProjects(String query) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final projectsData = await _db.searchProjects(_userId!, query);
      final projects = <ProjectModel>[];

      for (final projectData in projectsData) {
        // Create a mutable copy of the project data
        final mutableProjectData = Map<String, dynamic>.from(projectData);

        // Get client data for each project
        final clientData = await _db.getClientById(projectData['client_id']);
        if (clientData != null) {
          mutableProjectData['clients'] = clientData;
        }
        projects.add(ProjectModel.fromJson(mutableProjectData));
      }

      return projects;
    } catch (e) {
      throw Exception('Failed to search projects: $e');
    }
  }

  // Filter projects by status
  static Future<List<ProjectModel>> getProjectsByStatus(
      ProjectStatus status) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final projectsData = await _db.getProjectsByStatus(_userId!, status.name);
      final projects = <ProjectModel>[];

      for (final projectData in projectsData) {
        // Create a mutable copy of the project data
        final mutableProjectData = Map<String, dynamic>.from(projectData);

        // Get client data for each project
        final clientData = await _db.getClientById(projectData['client_id']);
        if (clientData != null) {
          mutableProjectData['clients'] = clientData;
        }
        projects.add(ProjectModel.fromJson(mutableProjectData));
      }

      return projects;
    } catch (e) {
      throw Exception('Failed to filter projects by status: $e');
    }
  }

  // Get project count by client
  static Future<int> getProjectCountByClient(String clientId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final projectsData = await _db.getProjectsByClient(_userId!, clientId);
      return projectsData.length;
    } catch (e) {
      throw Exception('Failed to get project count: $e');
    }
  }

  // Get overdue projects
  static Future<List<ProjectModel>> getOverdueProjects() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final allProjects = await getAllProjects();
      final now = DateTime.now();

      return allProjects.where((project) {
        if (project.endDate == null) return false;
        if (project.status == ProjectStatus.completed ||
            project.status == ProjectStatus.cancelled) {
          return false;
        }
        return project.endDate!.isBefore(now);
      }).toList()
        ..sort((a, b) => a.endDate!.compareTo(b.endDate!));
    } catch (e) {
      throw Exception('Failed to fetch overdue projects: $e');
    }
  }

  // Get project statistics
  static Future<Map<String, dynamic>> getProjectStatistics() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final projects = await getAllProjects();

      final stats = {
        'total': projects.length,
        'notStarted': 0,
        'inProgress': 0,
        'onHold': 0,
        'completed': 0,
        'cancelled': 0,
        'overdue': 0,
        'totalValue': 0.0,
      };

      final now = DateTime.now();

      for (final project in projects) {
        // Count by status
        switch (project.status) {
          case ProjectStatus.notStarted:
            stats['notStarted'] = (stats['notStarted'] as int) + 1;
            break;
          case ProjectStatus.inProgress:
            stats['inProgress'] = (stats['inProgress'] as int) + 1;
            break;
          case ProjectStatus.onHold:
            stats['onHold'] = (stats['onHold'] as int) + 1;
            break;
          case ProjectStatus.completed:
            stats['completed'] = (stats['completed'] as int) + 1;
            break;
          case ProjectStatus.cancelled:
            stats['cancelled'] = (stats['cancelled'] as int) + 1;
            break;
        }

        // Check if overdue
        if (project.endDate != null &&
            project.endDate!.isBefore(now) &&
            project.status != ProjectStatus.completed &&
            project.status != ProjectStatus.cancelled) {
          stats['overdue'] = (stats['overdue'] as int) + 1;
        }

        // Calculate total value
        if (project.pricingType == PricingType.fixedPrice &&
            project.fixedAmount != null) {
          stats['totalValue'] =
              (stats['totalValue'] as double) + project.fixedAmount!;
        } else if (project.pricingType == PricingType.hourlyRate &&
            project.hourlyRate != null &&
            project.actualHours != null) {
          final value = project.hourlyRate! * project.actualHours!;
          stats['totalValue'] = (stats['totalValue'] as double) + value;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get project statistics: $e');
    }
  }
}
