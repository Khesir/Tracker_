import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/note_model.dart';
import 'package:time_track/core/models/project_model.dart';
import 'package:time_track/core/state/stream_state.dart';
import 'package:time_track/features/notes/domain/controller/notes_controller.dart';
import 'package:time_track/features/notes/domain/repository/notes_repository.dart';
import 'package:time_track/features/projects/domain/repository/projects_repository.dart';

class FakeNotesRepository implements NotesRepository {
  final List<String> calls;
  final List<NoteModel> notes = [];

  FakeNotesRepository([List<String>? sharedCalls]) : calls = sharedCalls ?? [];

  @override
  Future<List<NoteModel>> getAll() async => notes;

  @override
  Future<NoteModel?> getById(String id) async =>
      notes.where((n) => n.id == id).firstOrNull;

  @override
  Future<void> save(NoteModel note) async {
    calls.add('save:${note.id}');
    notes.removeWhere((n) => n.id == note.id);
    notes.add(note);
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
    notes.removeWhere((n) => n.id == id);
  }

  @override
  Future<void> unlinkFromProject(String projectId) async {
    calls.add('unlinkFromProject:$projectId');
  }
}

class FakeProjectsRepository implements ProjectsRepository {
  final List<String> calls;
  final List<ProjectModel> projects = [];
  final List<ProjectModel> deleted = [];

  FakeProjectsRepository([List<String>? sharedCalls]) : calls = sharedCalls ?? [];

  @override
  Future<List<ProjectModel>> getAll() async => projects;

  @override
  Future<ProjectModel?> getById(String id) async =>
      projects.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> save(ProjectModel project) async {
    calls.add('save:${project.id}');
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
  }

  @override
  Future<void> softDelete(String id) async {
    calls.add('softDelete:$id');
  }

  @override
  Future<void> restore(String id) async {
    calls.add('restore:$id');
  }

  @override
  Future<void> purge(String id) async {
    calls.add('purge:$id');
  }

  @override
  Future<List<ProjectModel>> getDeleted() async => deleted;

  @override
  Future<void> unlinkNote(String projectId) async {
    calls.add('unlinkNote:$projectId');
  }
}

NoteModel _note({required String id, String noteJson = ''}) {
  return NoteModel(
    id: id,
    noteJson: noteJson,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late FakeNotesRepository notesRepo;
  late FakeProjectsRepository projectsRepo;
  late NotesController controller;

  setUp(() {
    notesRepo = FakeNotesRepository();
    projectsRepo = FakeProjectsRepository();
    controller = NotesController(notesRepo, projectsRepo);
  });

  group('load', () {
    test('populates uiState with notes from the repository', () async {
      notesRepo.notes.add(_note(id: 'n1'));
      notesRepo.notes.add(_note(id: 'n2'));

      await controller.load();

      expect(controller.uiState.state, isA<AsyncData<List<NoteModel>>>());
      final data = (controller.uiState.state as AsyncData<List<NoteModel>>).data;
      expect(data.map((n) => n.id).toSet(), {'n1', 'n2'});
    });
  });

  group('create', () {
    test('saves a new empty note and reloads the list', () async {
      final created = await controller.create();

      expect(created.noteJson, '');
      expect(notesRepo.calls, ['save:${created.id}']);
      expect(notesRepo.notes.map((n) => n.id), [created.id]);

      final data = (controller.uiState.state as AsyncData<List<NoteModel>>).data;
      expect(data.map((n) => n.id), [created.id]);
    });
  });

  group('update', () {
    test('saves the note through the repository and reloads', () async {
      final note = _note(id: 'n1', noteJson: 'a');
      notesRepo.notes.add(note);

      await controller.update(note.copyWith(noteJson: 'b'));

      expect(notesRepo.calls, ['save:n1']);
      final result = await notesRepo.getById('n1');
      expect(result!.noteJson, 'b');
    });
  });

  group('delete', () {
    test('deletes the note through the repository and reloads', () async {
      notesRepo.notes.add(_note(id: 'n1'));

      await controller.delete('n1');

      expect(notesRepo.calls, ['delete:n1']);
      expect(notesRepo.notes, isEmpty);
    });
  });

  group('allProjects', () {
    test('delegates to ProjectsRepository.getAll', () async {
      projectsRepo.projects.add(ProjectModel(
        id: 'p1',
        name: 'Project 1',
        colorHex: '#FFFFFF',
        createdAt: DateTime(2026, 1, 1),
        noteId: 'n1',
      ));

      final result = await controller.allProjects();

      expect(result.map((p) => p.id), ['p1']);
    });
  });
}
