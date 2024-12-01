// QuickTask: Flutter Task Management App with Back4App Integration

// Import Required Packages
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

    // 'nqyXTC9a00xbWulze3aGLMkQHVfCOtjHkW6voOss',
    // 'https://parseapi.back4app.com',
    // clientKey: 'nuKN9gmD8AR5FogyA72vRmwL1XZZDSWstFFPznSu',
    // autoSendSessionId: true,
  // Initialize Back4App
  const appId = 'nqyXTC9a00xbWulze3aGLMkQHVfCOtjHkW6voOss';
  const clientKey = 'nuKN9gmD8AR5FogyA72vRmwL1XZZDSWstFFPznSu';
  const serverUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(appId, serverUrl, clientKey: clientKey);

  runApp(QuickTaskApp());
}


class QuickTaskApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickTask',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}

// User Authentication
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Future<void> loginUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Username and Password cannot be empty')),
    );
    return;
  }

    final user = ParseUser(username, password, null);
    var response = await user.login();

    if (response.success) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) =>TaskListScreen(user: user)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${response.error?.message}')),
      );
    }
  }

  Future<void> signUpUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Username and Password cannot be empty')),
    );
    return;
  }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email is required for sign-up')),
      );
      return;
    }

    final user = ParseUser(username, password, email);
    var response = await user.signUp(allowWithoutEmail: false);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign Up Successful. Please log in.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign Up Failed: ${response.error?.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quick Task'), backgroundColor: Color(0xFFFFD65C)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
            'Login',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email (for Sign Up)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginUser,
              child: Text('Login'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: signUpUser,
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

// Task Management
class TaskListScreen extends StatefulWidget {
  final ParseUser user;

  TaskListScreen({required this.user});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<ParseObject> tasks = [];

  Future<void> fetchTasks() async {
    final query = QueryBuilder<ParseObject>(ParseObject('Task'))
      ..whereEqualTo('userName', widget.user.username);
    final response = await query.query();

    if (response.success && response.results != null) {
      setState(() {
        tasks = response.results as List<ParseObject>;
      });
    }
  }

  Future<void> addTask(String title, DateTime dueDate) async {
    final task = ParseObject('Task')
      ..set('title', title)
      ..set('dueDate', dueDate)
      ..set('isCompleted', false)
      ..set('userName', widget.user.username);

    await task.save();
    fetchTasks();
  }

  Future<void> deleteTask(String objectId) async {
    final task = ParseObject('Task')..objectId = objectId;
    await task.delete();
    fetchTasks();
  }

  Future<void> toggleTaskCompletion(ParseObject task) async {
    task.set('isCompleted', !(task.get<bool>('isCompleted') ?? false));
    await task.save();
    fetchTasks();
  }

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task List')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final title = task.get<String>('title') ?? 'No Title';
          final dueDate = task.get<DateTime>('dueDate')?.toLocal().toString() ?? '';
          final isCompleted = task.get<bool>('isCompleted') ?? false;

          return ListTile(
            title: Text(title),
            subtitle: Text('Due: $dueDate'),
            trailing: Checkbox(
              value: isCompleted,
              onChanged: (value) => toggleTaskCompletion(task),
            ),
            onLongPress: () => deleteTask(task.objectId!),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final titleController = TextEditingController();
          final dueDateController = TextEditingController();

          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add Task'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Task Title'),
                    ),
                    TextField(
                      controller: dueDateController,
                      decoration: InputDecoration(labelText: 'Due Date (yyyy-mm-dd)'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      final title = titleController.text;
                      final dueDate = DateTime.tryParse(dueDateController.text);
                      if (title.isNotEmpty && dueDate != null) {
                        addTask(title, dueDate);
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}