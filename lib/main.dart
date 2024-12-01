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

    bool _isSignUp = false; // Track whether we're in SignUp mode


  Future<void> loginUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Username and Password cannot be empty'),
                  backgroundColor: Colors.amber,),
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
        SnackBar(content: Text('Login Failed: ${response.error?.message}'),
                  backgroundColor: Colors.red,),
      );
    }
  }

  Future<void> signUpUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Username and Password cannot be empty'),
                  backgroundColor: Colors.amber,),
    );
    return;
  }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email is required for sign-up'),
                  backgroundColor: Colors.amber,),
      );
      return;
    }

    final user = ParseUser(username, password, email);
    var response = await user.signUp(allowWithoutEmail: false);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign Up Successful. Please log in.'),
                  backgroundColor: Colors.green,),
      );
      setState(() {
                _isSignUp = !_isSignUp; // Toggle between login and signup
              });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign Up Failed: ${response.error?.message}'),
                  backgroundColor: Colors.red,),
      );
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quick Task'),
        backgroundColor: Color(0xFFFFD65C), // Hex color #FFD65C
        actions: [
          // Sign Up Button positioned at the top-right corner
          IconButton(
            icon: Icon(Icons.app_registration),
            onPressed: () {
              setState(() {
                _isSignUp = !_isSignUp; // Toggle between login and signup
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Welcome to Quick Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD65C), // Hex color #FFD65C
              ),
            ),
            SizedBox(height: 20), // Adds space between the text and text fields

            // Username text field
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 10), // Adds space between text fields

            // Password text field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 10), // Adds space between text fields

            // Only show the Email field if it's Sign Up mode
            if (_isSignUp) 
              ...[
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email (for Sign Up)'),
                ),
                SizedBox(height: 10), // Adds space between text fields
              ],

            SizedBox(height: 20), // Adds space before the buttons

            // If SignUp mode, show SignUp button, else show Login button
            if (_isSignUp)
              ElevatedButton(
                onPressed: signUpUser,
                child: Text('Sign Up'),
              )
            else
              ElevatedButton(
                onPressed: loginUser,
                child: Text('Login'),
              ),

            SizedBox(height: 10), // Adds space between buttons

            // The other button (Login/SignUp) swaps based on the mode
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = !_isSignUp; // Toggle between login and signup
                });
              },
              child: Text(_isSignUp ? 'Already have an account? Login' : 'Create an account'),
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
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task added successfully'), backgroundColor: Colors.green),
      );
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
  final myuser = widget?.user?.username != null ? widget.user.username : 'User';
  return Scaffold(
    appBar: AppBar(
      title: Text('Task List for ' + (myuser ?? 'User')),
      backgroundColor: Color(0xFFFFD65C), // Yellow Color #FFD65C
    ),
    body: ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final title = task.get<String>('title') ?? 'No Title';
        final dueDate = task.get<DateTime>('dueDate')?.toLocal().toString() ?? '';
        final isCompleted = task.get<bool>('isCompleted') ?? false;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey), // Add border for list items
            borderRadius: BorderRadius.circular(8), // Optional: rounded corners
            color: isCompleted ? Colors.green.shade100 : Colors.white, // Highlight completed tasks with green
          ),
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10), // Optional: Add margin for spacing
          child: ListTile(
            title: Text(
              title,
              style: TextStyle(
                fontSize: 18, // Increase font size for the title
                fontWeight: FontWeight.bold, // Optional: make the title bold
              )),
            subtitle: Text('Due: $dueDate'),
            trailing: Checkbox(
              value: isCompleted,
              onChanged: (value) => toggleTaskCompletion(task),
            ),
            onLongPress: () => _showDeleteConfirmationDialog(task.objectId!)
          ),
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
// Show confirmation dialog before deleting task
void _showDeleteConfirmationDialog(String taskId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              deleteTask(taskId); // Perform the delete action
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task deleted successfully!'),
                  backgroundColor: Colors.green, // Success color
                ),
              );
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Yes'),
          ),
        ],
      );
    },
  );
}
}