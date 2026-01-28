class AdminConfig {
  static const Map<String, String> adminCredentials = {
    'harshitvarshney822@gmail.com': 'Harshit@1212',
    'mahakgupta956@gmail.com':'mahak@123',

  };

  static bool isAdmin(String? email) {
    if (email == null) return false;
    return adminCredentials.containsKey(email.toLowerCase());
  }

  static bool isValidAdmin(String email, String password) {
    return adminCredentials[email.toLowerCase()] == password;
  }

  static String getAdminRole(String email) {
    if (email.toLowerCase() == 'harshitvarshney822@gmail.com') {
      return 'Super Admin';
    }
    return 'Admin';
  }
}
