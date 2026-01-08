import 'package:flutter/material.dart';
import 'package:sms_apk/school/auth_screen/login.dart';
import 'package:sms_apk/hotel/auth/hotelLogin.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  // GlobalKeys for sections
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedService;

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _scrollToSection(String section) {
    GlobalKey? key;
    switch (section) {
      case 'services':
        key = _servicesKey;
        break;
      case 'about':
        key = _aboutKey;
        break;
      case 'contact':
        key = _contactKey;
        break;
    }
    if (key != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    Navigator.of(context).pop(); // Close drawer if open
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.1),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF126666)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.business, color: Color(0xFF126666), size: 28),
            const SizedBox(width: 8),
            Text(
              size.width < 600 ? 'EasyWay' : 'EasyWaySolution',
              style: const TextStyle(
                color: Color(0xFF126666),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (size.width >= 768) ...[
            TextButton(
              onPressed: () => _scrollToSection('services'),
              child: const Text(
                'Services',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () => _scrollToSection('about'),
              child: const Text(
                'About',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () => _scrollToSection('contact'),
              child: const Text(
                'Contact',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Handle demo request
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF126666),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Request Demo'),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      drawer: size.width < 768 ? _buildMobileDrawer() : null,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(),
            _buildServicesSection(),
            _buildAboutSection(),
            _buildContactSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF126666)),
            child: Text(
              'EasyWaySolution',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(title: const Text('Services'), onTap: () => _scrollToSection('services')),
          ListTile(title: const Text('About'), onTap: () => _scrollToSection('about')),
          ListTile(title: const Text('Contact'), onTap: () => _scrollToSection('contact')),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle demo request
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF126666),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Request Demo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF126666), Color(0xFF1e7878), Color(0xFF0f5555)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
        child: Column(
          children: [
            Text(
              'Best School & Hotel Management Software in India',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width < 768 ? 28 : 48,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Transform your educational institution or hospitality business with our comprehensive management system.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: MediaQuery.of(context).size.width < 768 ? 16 : 20,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _scrollToSection('services'),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View Our Solutions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF126666),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      key: _servicesKey,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
      child: Column(
        children: [
          const Text(
            'Services',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF095555)),
          ),
          const SizedBox(height: 16),
          const Text(
            'School Management System & Hotel Management Software',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, color: Color(0xFF126666), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose from our specialized management solutions designed for educational institutions and hospitality businesses across India',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 768) {
                return Column(
                  children: [
                    _buildServiceCard(
                      icon: Icons.school_rounded,
                      title: 'School Management System',
                      description: 'Complete school ERP software for student admission, attendance, fees, exams, and academics.',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceCard(
                      icon: Icons.hotel_rounded,
                      title: 'Hotel Management System',
                      description: 'Advanced hotel booking software with room reservation, guest check-in/out, billing, and POS.',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelLoginScreen()));
                      },
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.school_rounded,
                        title: 'School Management System',
                        description: 'Complete school ERP software for student admission, attendance, fees, exams, and academics.',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.hotel_rounded,
                        title: 'Hotel Management System',
                        description: 'Advanced hotel booking software with room reservation, guest check-in/out, billing, and POS.',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelLoginScreen()));
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF126666), Color(0xFF1e7878)]),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF126666))),
            const SizedBox(height: 12),
            Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Start Free Trial', style: TextStyle(color: Color(0xFF126666), fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Color(0xFF126666), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      key: _aboutKey,
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
      child: Column(
        children: [
          const Text(
            'Why Choose EasyWaySolution?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF126666)),
          ),
          const SizedBox(height: 16),
          Text(
            'India\'s trusted management software provider with 1000+ satisfied customers across education and hospitality sectors',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 768) {
                return Column(
                  children: [
                    _buildFeatureCard(icon: Icons.people, title: 'User-Friendly Interface', description: 'Simple and intuitive design.', gradient: const [Color(0xFF126666), Color(0xFF1e7878)]),
                    const SizedBox(height: 16),
                    _buildFeatureCard(icon: Icons.security, title: '100% Secure & Cloud-Based', description: 'Bank-level security.', gradient: const [Color(0xFF1e7878), Color(0xFF0f5555)]),
                    const SizedBox(height: 16),
                    _buildFeatureCard(icon: Icons.bar_chart, title: 'Smart Reports & Analytics', description: 'Automated reports.', gradient: const [Color(0xFF0f5555), Color(0xFF126666)]),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildFeatureCard(icon: Icons.people, title: 'User-Friendly Interface', description: 'Simple and intuitive design.', gradient: const [Color(0xFF126666), Color(0xFF1e7878)])),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFeatureCard(icon: Icons.security, title: '100% Secure & Cloud-Based', description: 'Bank-level security.', gradient: const [Color(0xFF1e7878), Color(0xFF0f5555)])),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFeatureCard(icon: Icons.bar_chart, title: 'Smart Reports & Analytics', description: 'Automated reports.', gradient: const [Color(0xFF0f5555), Color(0xFF126666)])),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String description, required List<Color> gradient}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(32)), child: Icon(icon, color: Colors.white, size: 32)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF126666))),
          const SizedBox(height: 12),
          Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      key: _contactKey,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF126666), Color(0xFF1e7878), Color(0xFF0f5555)]),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
      child: Column(
        children: [
          const Text('Get Free Demo of School & Hotel Management Software', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text(
            'Ready to digitize your school or hotel operations? Book a free demo today and see how our software can transform your business.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.5),
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 768) {
                return Column(children: [_buildContactInfo(), const SizedBox(height: 32), _buildContactForm()]);
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(child: _buildContactInfo()), const SizedBox(width: 32), Expanded(child: _buildContactForm())],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        _buildContactItem(icon: Icons.phone, title: 'Call Us Now', subtitle: '+91 98765 43210'),
        const SizedBox(height: 24),
        _buildContactItem(icon: Icons.email, title: 'Email Support', subtitle: 'support@easywaysolution.com'),
      ],
    );
  }

  Widget _buildContactItem({required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(24)), child: Icon(icon, color: Colors.white, size: 24)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14))]),
      ],
    );
  }

  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedService,
            decoration: const InputDecoration(
              labelText: 'Select Service',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            ),
            dropdownColor: Colors.white,
            items: ['School Management', 'Hotel Management']
                .map((service) => DropdownMenuItem(value: service, child: Text(service)))
                .toList(),
            onChanged: (value) => setState(() => _selectedService = value),
            validator: (value) => value == null || value.isEmpty ? 'Please select a service' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo request submitted!')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF126666),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.grey[100],
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: const Center(
        child: Text(
          '© 2025 EasyWaySolution. All rights reserved.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }
}
