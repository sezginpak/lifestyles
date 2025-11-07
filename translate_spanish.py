#!/usr/bin/env python3
"""
Spanish Translation Updater - Phase 3
Updates Spanish localization file with more translations
"""

import re
from pathlib import Path

# İspanyolca çeviriler - Phase 1 + Phase 2
TRANSLATIONS = {
    # === PHASE 1: BASICS (64 keys) ===
    
    # TAB TITLES (10)
    "tab.moodJournal": "Diario de Estado de Ánimo",
    "tab.memories": "Recuerdos",
    "tab.activities": "Actividades",
    "tab.analytics": "Análisis",
    "tab.contacts": "Amigos",
    "tab.dashboard": "Inicio",
    "tab.goals": "Objetivos",
    "tab.location": "Actividad",
    "tab.settings": "Configuración",
    "aibrain.tab.title": "Cerebro IA",

    # COMMON BUTTONS (20)
    "button.save": "Guardar",
    "button.cancel": "Cancelar",
    "button.delete": "Eliminar",
    "button.edit": "Editar",
    "button.close": "Cerrar",
    "button.ok": "Aceptar",
    "button.update": "Actualizar",
    "button.details": "Detalles",
    "button.complete": "Completar",
    "button.message": "Mensaje",
    "button.call": "Llamar",
    "button.share": "Compartir",
    "button.retry": "Reintentar",
    "button.preview": "Vista Previa",
    "button.analyze": "Iniciar Análisis",
    "button.reanalyze": "Re-analizar",
    "button.remove.photo": "Quitar Foto",
    "button.weekly.analysis": "Crear Análisis Semanal",
    "button.edit.title": "Editar Título",
    "button.view.details": "Ver Detalles",

    # NAVIGATION (15)
    "nav.daily.insight": "Tu Perspectiva Diaria",
    "nav.save.mood": "Guardar Estado de Ánimo",
    "nav.emoji.picker": "Elegir Emoji",
    "nav.add.note": "Añadir Nota",
    "nav.tags": "Etiquetas",
    "nav.frequent.tags": "Etiquetas Frecuentes",
    "nav.ai.brain": "Cerebro IA",
    "nav.ai.chat": "Chat IA",

    # LABELS (5)
    "label.ai.chat": "Chat IA",

    # PLACEHOLDERS (15)
    "placeholder.title": "Título",
    "placeholder.mood.note": "¿Qué pasó hoy?",
    "placeholder.emoji.search": "Buscar emoji...",
    "placeholder.tag.name": "Nombre de etiqueta",
    "placeholder.custom.tag": "Añadir etiqueta personalizada",
    "placeholder.etiket.ekle": "Añadir etiqueta",
    "placeholder.notes": "Tus notas...",
    "placeholder.avatar.emoji": "Emoji de Avatar",
    "placeholder.name": "Nombre",
    "placeholder.phone": "Teléfono",
    "placeholder.place.name": "Nombre del lugar",

    # ERRORS (10)
    "error.invalid.coordinates": "Coordenadas inválidas",
    "error.check.updates": "Buscar Actualizaciones",
    "error.contact.support": "Por favor contacta con soporte si el problema persiste",
    "error.restart.app": "Reiniciar Aplicación",
    "error.retry": "Reintentar",

    # MOOD (5)
    "mood.happy": "Feliz",
    "mood.sad": "Triste",
    "mood.add.tags": "Añadir etiquetas",

    # FRIENDS (3)
    "friend.notes": "Notas",

    # COMMON (15)
    "common.save": "Guardar",
    "common.cancel": "Cancelar",
    "common.delete": "Eliminar",
    "common.edit": "Editar",
    "common.add": "Añadir",
    "common.settings": "Configuración",
    "common.back": "Atrás",
    "common.next": "Siguiente",
    "common.close": "Cerrar",
    "common.ok": "Aceptar",

    # === PHASE 2: EXPANDED CATEGORIES (200+ keys) ===
    
    # ACHIEVEMENTS (20)
    "achievement.category.consistency": "Consistencia",
    "achievement.category.goal": "Objetivos",
    "achievement.category.habit": "Hábitos",
    "achievement.category.special": "Especial",
    "achievement.first.goal.title": "Primer Objetivo",
    "achievement.first.goal.desc": "Crea tu primer objetivo",
    "achievement.first.habit.title": "Primer Hábito",
    "achievement.first.habit.desc": "Crea tu primer hábito",
    "achievement.week.warrior.title": "Guerrero Semanal",
    "achievement.week.warrior.desc": "Completa objetivos/hábitos durante 7 días consecutivos",
    "achievement.month.champion.title": "Campeón Mensual",
    "achievement.month.champion.desc": "Completa durante 30 días consecutivos",
    "achievement.hundred.master.title": "Maestro de los Cien",
    "achievement.hundred.master.desc": "Completa durante 100 días consecutivos",
    "achievement.habit.master.title": "Maestro de Hábitos",
    "achievement.habit.master.desc": "Racha de 30 días en un hábito",
    "achievement.legendary.habit.title": "Hábito Legendario",
    "achievement.legendary.habit.desc": "Racha de 90 días en un hábito",
    "achievement.goal.hunter.title": "Cazador de Objetivos",
    "achievement.health.king.title": "Rey de la Salud",
    "achievement.health.king.desc": "Completa 5 objetivos de salud",

    # ACTIVITIES (30)
    "activity.complete.button": "Completar Actividad",
    "activity.completed.alert.title": "¡Actividad Completada!",
    "activity.completed.alert.message": "¡Felicidades! ¡Ganaste %lld puntos!",
    "activity.completed.alert.button": "¡Genial!",
    "activity.detail.title": "Detalle de Actividad",
    "activity.info.title": "Información de Actividad",
    "activity.info.difficulty": "Dificultad",
    "activity.info.duration": "Duración",
    "activity.info.points": "Puntos",
    "activity.info.views": "Vistas",
    "activity.info.last_viewed": "Última Vista",
    "activity.completion.history": "Historial de Finalización",
    "activity.current.outdoor": "Al Aire Libre",
    "activity.type.creative": "Creativo",
    "activity.type.exercise": "Ejercicio",
    "activity.type.learning": "Aprendizaje",
    "activity.type.outdoor": "Al Aire Libre",
    "activity.type.relax": "Relajarse",
    "activity.type.social": "Social",
    "activity.suggestion.walk.title": "Dar un Paseo 🚶",
    "activity.suggestion.walk.desc": "Camina 30 minutos, toma aire fresco",
    "activity.suggestion.exercise.title": "Hacer Ejercicio 🏃",
    "activity.suggestion.exercise.desc": "Ve al parque cercano a correr",
    "activity.suggestion.meditation.title": "Meditar 🧘",
    "activity.suggestion.meditation.desc": "Haz 10 minutos de ejercicios de respiración",
    "activity.suggestion.cafe.title": "Ir a un Café ☕",
    "activity.suggestion.cafe.desc": "¿Qué tal un café con un amigo?",
    "activity.suggestion.creative.title": "Sé Creativo 🎨",
    "activity.suggestion.creative.desc": "Dibuja o escribe algo",
    "activity.suggestion.learn.title": "Aprende Algo Nuevo 📖",
    "activity.suggestion.learn.desc": "Inicia un curso en línea",

    # FRIENDS (15)
    "friend.add": "Añadir Amigo",
    "friend.edit": "Editar Amigo",
    "friend.delete": "Eliminar Amigo",
    "friend.achievements": "Logros",
    "friend.activities.footer": "Actividades que hacen o quieren hacer juntos (separadas por comas)",
    "friend.basic.info": "Información Básica",
    "friend.best.day.contact": "Mejor Día",
    "friend.change.emoji": "Cambiar Emoji",
    "friend.comma.separated": "Separar con comas",
    "friend.communication.frequency": "Frecuencia de Comunicación",
    "friend.last.30.days": "Últimos 30 Días",
    "friend.relationship.health": "Salud de la Relación",
    "friend.action.ai.chat": "Chat IA",
    "friend.action.mark.contacted": "Marcar Completado",

    # GOALS (25)
    "goal.achievements": "Logros",
    "goal.ai.coaching": "Coaching IA",
    "goal.all.templates": "Todas las Plantillas",
    "goal.blank.title": "Objetivo en Blanco",
    "goal.blank.description": "Empieza desde cero",
    "goal.category.career": "Carrera",
    "goal.category.education": "Educación",
    "goal.category.family": "Familia",
    "goal.category.finance": "Finanzas",
    "goal.category.fitness": "Fitness",
    "goal.category.health": "Salud",
    "goal.category.hobby": "Pasatiempo",
    "goal.category.home": "Hogar",
    "goal.category.personal": "Personal",
    "goal.category.relationship": "Relaciones",
    "goal.category.social": "Social",
    "goal.category.travel": "Viajes",
    "goal.category.work": "Trabajo",
    "goal.daily": "Diario",
    "goal.weekly": "Semanal",
    "goal.monthly": "Mensual",
    "goal.new": "Nuevo Objetivo",
    "goal.title": "Objetivo",
    "goal.ai.generating": "IA generando descripción...",
    "goal.basic.info.description": "Establece el título y categoría de tu objetivo",

    # HABITS (15)
    "habit.blank.title": "Hábito en Blanco",
    "habit.blank.description": "Empieza desde cero",
    "habit.daily": "Diario",
    "habit.weekly": "Semanal",
    "habit.monthly": "Mensual",
    "habit.new": "Nuevo Hábito",
    "habit.title": "Hábito",
    "habit.description.optional": "Descripción (Opcional)",
    "habit.error.name.empty": "El nombre del hábito no puede estar vacío",
    "habit.target.count": "Cuenta Objetivo",
    "habit.ai.generating": "IA está generando descripción...",
    "habit.ai.suggestion": "Sugerencia IA",
    "habit.basic.info.description": "Establece el nombre y frecuencia de tu hábito",
    "habit.error.name.too.long": "El nombre del hábito es demasiado largo",
    "habit.error.description.too.long": "La descripción del hábito es demasiado larga",
    
    # MOOD EXPANDED (15)
    "mood.great": "Genial",
    "mood.good": "Bien",
    "mood.okay": "Normal",
    "mood.notGreat": "No Muy Bien",
    "mood.analytics.highlights": "Destacados",
    "mood.analytics.pattern": "Patrón",
    "mood.analytics.suggestions": "Sugerencias",
    "mood.analytics.detailed.analysis": "Análisis Detallado",
    "mood.ai.analysis.ready": "Análisis IA Listo",
    "mood.30.day.heatmap": "Mapa de Calor de 30 Días",
    "mood.30plus.analysis": "Análisis de 30+ Días",
    "mood.correlation.empty.message": "Rastrea tus estados de ánimo para ver correlaciones con amigos, objetivos y ubicaciones",
    
    # COMMON UI (20)
    "today": "Hoy",
    "yesterday": "Ayer",
    "tomorrow": "Mañana",
    "this.week": "Esta Semana",
    "this.month": "Este Mes",
    "all": "Todos",
    "none": "Ninguno",
    "loading": "Cargando...",
    "saving": "Guardando...",
    "success": "Éxito",
    "failed": "Fallido",
    "completed": "Completado",
    "pending": "Pendiente",
    "active": "Activo",
    "inactive": "Inactivo",
    "start": "Comenzar",
    "stop": "Detener",
    "pause": "Pausar",
    "resume": "Reanudar",
    "continue": "Continuar",

    # === PHASE 3: EXPANDED FEATURES (140+ keys) ===

    # SETTINGS (30)
    "settings.title": "Configuración",
    "settings.general.settings": "Configuración General",
    "settings.notifications.title": "Notificaciones",
    "settings.notifications.permission": "Permiso de Notificaciones",
    "settings.notifications.permission.desc": "Permitir notificaciones para recordatorios",
    "settings.notifications.types": "Tipos de Notificaciones",
    "settings.notifications.friend.reminders": "Recordatorios de Amigos",
    "settings.notifications.goal.reminders": "Recordatorios de Objetivos",
    "settings.notifications.habit.reminders": "Recordatorios de Hábitos",
    "settings.notifications.quiet.hours": "Horas Silenciosas",
    "settings.language": "Idioma",
    "settings.language.change.title": "Cambiar Idioma",
    "settings.language.change.button": "Cambiar Idioma",
    "settings.appearance.profile": "Apariencia y Perfil",
    "settings.privacy": "Privacidad",
    "settings.privacy.policy": "Política de Privacidad",
    "settings.terms.of.use": "Términos de Uso",
    "settings.about.title": "Acerca de",
    "settings.version": "Versión",
    "settings.data.management.title": "Gestión de Datos",
    "settings.data.export": "Exportar Datos",
    "settings.data.restore.backup": "Restaurar Copia de Seguridad",
    "settings.delete.all.data": "Eliminar Todos los Datos",
    "settings.delete.warning": "Esta acción no se puede deshacer",
    "settings.location.title": "Ubicación",
    "settings.location.permission": "Permiso de Ubicación",
    "settings.location.permission.desc": "Permitir acceso a tu ubicación",
    "settings.ai.features": "Características de IA",
    "settings.ai.privacy.settings": "Configuración de Privacidad de IA",
    "settings.premium.title": "Premium",
    "settings.premium.upgrade": "Actualizar a Premium",

    # LOCATION (30)
    "location.history": "Historial de Ubicación",
    "location.saved.places.empty": "No hay lugares guardados",
    "location.current": "Ubicación Actual",
    "location.home.location.set": "Establecer como Casa",
    "location.place.name": "Nombre del Lugar",
    "location.place.category": "Categoría del Lugar",
    "location.place.notes.optional": "Notas (Opcional)",
    "location.place.emoji": "Emoji del Lugar",
    "location.place.radius": "Radio del Lugar",
    "location.place.saved.message": "Lugar guardado exitosamente",
    "location.visits.count": "Número de Visitas",
    "location.recent.visits": "Visitas Recientes",
    "location.total.distance": "Distancia Total",
    "location.record.count": "Registros",
    "location.type.home": "Casa",
    "location.type.work": "Trabajo",
    "location.type.outside": "Fuera",
    "location.unknown": "Desconocido",
    "location.at.place": "En este lugar",
    "location.not.at.saved.place": "No en lugar guardado",
    "location.radius.meters": "Radio (metros)",
    "location.information": "Información",
    "location.tracking.info": "Información de Seguimiento",
    "location.my.favorites": "Mis Favoritos",
    "location.what.to.do": "Qué Hacer Aquí",
    "location.badges": "Insignias",
    "location.points": "Puntos",
    "location.ongoing": "En Curso",
    "location.delete.confirm": "¿Eliminar este lugar?",
    "location.place.basic.info": "Información Básica",
    "location.stay.duration": "Duración de Estancia",

    # PROFILE (20)
    "profile.my.profile": "Mi Perfil",
    "profile.my.info": "Mi Información",
    "profile.name": "Nombre",
    "profile.name.placeholder": "Tu nombre",
    "profile.age": "Edad",
    "profile.occupation": "Ocupación",
    "profile.occupation.placeholder": "Tu ocupación",
    "profile.basic.info": "Información Básica",
    "profile.about": "Acerca de",
    "profile.interests": "Intereses",
    "profile.hobbies": "Pasatiempos",
    "profile.core.values": "Valores Fundamentales",
    "profile.life.goals": "Metas de Vida",
    "profile.work.schedule": "Horario de Trabajo",
    "profile.living.arrangement": "Situación de Vivienda",
    "profile.add.interest": "Agregar Interés",
    "profile.add.hobby": "Agregar Pasatiempo",
    "profile.add.value": "Agregar Valor",
    "profile.saved": "Guardado",
    "profile.saved.message": "Perfil guardado exitosamente",

    # PREMIUM (20)
    "premium.title": "Premium",
    "premium.subtitle": "Desbloquea todas las funciones",
    "premium.upgrade": "Actualizar a Premium",
    "premium.upgrade.button": "Actualizar Ahora",
    "premium.label": "Premium",
    "premium.badge.title": "Miembro Premium",
    "premium.trial.3days": "Prueba de 3 Días",
    "premium.trial.info": "Prueba gratis durante 3 días",
    "premium.trial.active": "Prueba Activa",
    "premium.trial.days.remaining": "días restantes",
    "premium.monthly.subscription": "Suscripción Mensual",
    "premium.per.month": "por mes",
    "premium.plan.monthly": "Plan Mensual",
    "premium.plan.yearly": "Plan Anual",
    "premium.period.month": "mes",
    "premium.period.year": "año",
    "premium.savings.yearly": "Ahorra 20% con el plan anual",
    "premium.cancel.anytime": "Cancela en cualquier momento",
    "premium.restore.purchases": "Restaurar Compras",
    "premium.unlimited.usage": "Uso Ilimitado",

    # NOTIFICATIONS (20)
    "notification.center.empty.title": "Sin Notificaciones",
    "notification.center.empty.message": "No tienes notificaciones nuevas",
    "notification.group.today": "Hoy",
    "notification.group.yesterday": "Ayer",
    "notification.group.this.week": "Esta Semana",
    "notification.group.older": "Más Antiguas",
    "notification.mark.all.read": "Marcar Todas como Leídas",
    "notification.clear.all": "Borrar Todas",
    "notification.contact.reminder.title": "Recordatorio de Contacto",
    "notification.contact.reminder.body": "Es hora de contactar a tu amigo",
    "notification.goal.reminder.title": "Recordatorio de Objetivo",
    "notification.habit.reminder.title": "Recordatorio de Hábito",
    "notification.daily.activity.title": "Actividad Diaria",
    "notification.weekly.summary.title": "Resumen Semanal",
    "notification.motivation.title": "Mensaje Motivacional",
    "notification.go.outside.title": "Sal al Aire Libre",
    "notification.contact.time.title": "Hora de Contactar",
    "notification.contact.saved.title": "Contacto Guardado",
    "dashboard.notifications.title": "Notificaciones",
    "dashboard.notifications.show.all": "Ver Todas",

    # TIME & DATE (15)
    "today": "Hoy",
    "yesterday": "Ayer",
    "tomorrow": "Mañana",
    "this.week": "Esta Semana",
    "this.month": "Este Mes",
    "time.morning": "Mañana",
    "time.afternoon": "Tarde",
    "time.evening": "Noche",
    "time.night": "Madrugada",
    "time.all_day": "Todo el Día",
    "duration.days": "días",
    "duration.months": "meses",
    "duration.years": "años",
    "date.idea.romantic.picnic.title": "Picnic Romántico",
    "date.idea.cultural.museum.title": "Visita al Museo",

    # ANALYTICS (15)
    "analytics.main.title": "Análisis",
    "analytics.section.overview": "Resumen General",
    "analytics.section.mood": "Estado de Ánimo",
    "analytics.section.goals": "Objetivos",
    "analytics.section.habits": "Hábitos",
    "analytics.section.social": "Social",
    "analytics.section.location": "Ubicación",
    "analytics.timeRange.week": "Semana",
    "analytics.timeRange.month": "Mes",
    "analytics.timeRange.threeMonths": "3 Meses",
    "analytics.timeRange.year": "Año",
    "analytics.overview.wellness.excellent": "Excelente",
    "analytics.overview.wellness.good": "Bueno",
    "analytics.overview.wellness.average": "Promedio",
    "analytics.overview.wellness.poor": "Pobre",
}

def translate_file():
    """Translate Spanish localization file"""

    file_path = Path('LifeStyles/Resources/es.lproj/Localizable.strings')

    if not file_path.exists():
        print(f"❌ File not found: {file_path}")
        return

    print("🇪🇸 İspanyolca Çeviri Güncelleniyor - PHASE 2...")
    print(f"📁 Dosya: {file_path}")
    print(f"📝 Çeviri sayısı: {len(TRANSLATIONS)}\n")

    # Read file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Track changes
    updated_count = 0
    not_found = []

    # Replace translations
    for key, translation in sorted(TRANSLATIONS.items()):
        # Pattern: "key" = "old_value";
        pattern = rf'^("{key}"\s*=\s*)"[^"]*";'
        replacement = rf'\1"{translation}";'

        # Check if key exists
        if re.search(pattern, content, re.MULTILINE):
            # Replace
            new_content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

            if new_content != content:
                content = new_content
                updated_count += 1
                print(f"✅ {key}")
        else:
            not_found.append(key)

    # Write updated file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    # Summary
    print(f"\n{'='*60}")
    print(f"🎉 Phase 2 Tamamlandı!")
    print(f"✅ Güncellenen: {updated_count}/{len(TRANSLATIONS)}")
    print(f"📊 Başarı oranı: {updated_count/len(TRANSLATIONS)*100:.1f}%")

    if not_found:
        print(f"\n⚠️  Bulunamayan key'ler ({len(not_found)}):")
        for key in not_found[:15]:
            print(f"   - {key}")
        if len(not_found) > 15:
            print(f"   ... ve {len(not_found) - 15} key daha")

    print(f"\n💡 Sonraki adım:")
    print(f"   git add {file_path}")
    print(f"   git commit -m \"chore: İspanyolca çeviri Phase 2 - {updated_count} key\"")

if __name__ == '__main__':
    translate_file()
