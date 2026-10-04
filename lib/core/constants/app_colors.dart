 import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF6C2BD9);        // Violet principal
  static const Color primaryLight = Color(0xFFF3EEFF);   // Violet clair
  static const Color primaryDark = Color(0xFF4A1D96);    // Violet foncé
  

  // Couleur secondaire
  static const Color secondary = Color(0xFFF97316);      // Orange EDA LAUNCH

  // Couleurs des rôles
  static const Color entrepreneur = Color(0xFF6C2BD9);   // Violet entrepreneur
  static const Color mentor = Color(0xFF1A7A4A);         // Vert mentor
  static const Color financeur = Color(0xFFD97706);      // Orange financeur
  static const Color admin = Color(0xFF2563EB);          // Bleu admin
  
  // Couleurs claires des rôles
  static const Color mentorLight = Color(0xFFE8F5EE);

  // Couleurs de statut
  static const Color success = Color(0xFF1A7A4A);        // Vert succès
  static const Color successLight = Color(0xFFE8F5EE);   // Vert clair
  static const Color warning = Color(0xFFD97706);        // Orange warning
  static const Color warningLight = Color(0xFFFFF7ED);   // Orange clair
  static const Color error = Color(0xFFDC2626);          // Rouge erreur
  static const Color errorLight = Color(0xFFFEF2F2);     // Rouge clair
  static const Color info = Color(0xFF2563EB);           // Bleu info
  static const Color infoLight = Color(0xFFEFF6FF);      // Bleu clair

  // Couleurs de scoring
  static const Color scoreExcellent = Color(0xFF1A7A4A); // 90-100
  static const Color scoreGood = Color(0xFF2563EB);      // 75-89
  static const Color scoreMedium = Color(0xFFD97706);    // 60-74
  static const Color scoreWeak = Color(0xFFDC2626);      // 0-59

  // Couleurs neutres
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Couleurs texte
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Couleurs bordures
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocus = Color(0xFF6C2BD9);

  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C2BD9), Color(0xFF4A1D96)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scoreGradient = LinearGradient(
    colors: [Color(0xFF1A7A4A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Ombres
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  // Méthode utilitaire — couleur selon le score
  static Color getScoreColor(int score) {
    if (score >= 90) return scoreExcellent;
    if (score >= 75) return scoreGood;
    if (score >= 60) return scoreMedium;
    return scoreWeak;
  }

  // Méthode utilitaire — couleur selon le statut projet
  static Color getStatusColor(String status) {
    switch (status) {
      case 'brouillon': return grey500;
      case 'soumis': return info;
      case 'en_analyse': return warning;
      case 'accepte': return success;
      case 'rejete': return error;
      case 'finance': return primary;
      case 'en_suivi': return entrepreneur;
      default: return grey500;
    }
  }

  // Méthode utilitaire — couleur selon le rôle
  static Color getRoleColor(String role) {
    switch (role) {
      case 'entrepreneur': return entrepreneur;
      case 'mentor': return mentor;
      case 'financeur': return financeur;
      case 'admin': return admin;
      default: return primary;
    }
  }
}
