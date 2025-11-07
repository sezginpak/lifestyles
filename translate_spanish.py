#!/usr/bin/env python3
"""
Spanish Translation Updater
Updates Spanish localization file with translations
"""

import re
from pathlib import Path

# İspanyolca çeviriler - İlk 50 öncelikli key
TRANSLATIONS = {
    # TAB TITLES (5)
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
    "button.done": "Listo",
    "button.next": "Siguiente",
    "button.back": "Atrás",
    "button.close": "Cerrar",
    "button.add": "Añadir",
    "button.remove": "Quitar",
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

    # NAVIGATION (15)
    "nav.settings": "Configuración",
    "nav.profile": "Perfil",
    "nav.home": "Inicio",
    "nav.back": "Atrás",
    "nav.save": "Guardar",
    "nav.daily.insight": "Tu Perspectiva Diaria",
    "nav.save.mood": "Guardar Estado de Ánimo",
    "nav.emoji.picker": "Elegir Emoji",
    "nav.add.note": "Añadir Nota",
    "nav.tags": "Etiquetas",
    "nav.frequent.tags": "Etiquetas Frecuentes",
    "nav.ai.brain": "Cerebro IA",
    "nav.ai.chat": "Chat IA",

    # LABELS (20)
    "label.title": "Título",
    "label.description": "Descripción",
    "label.date": "Fecha",
    "label.time": "Hora",
    "label.name": "Nombre",
    "label.email": "Correo Electrónico",
    "label.password": "Contraseña",
    "label.confirm": "Confirmar",
    "label.optional": "Opcional",
    "label.required": "Obligatorio",
    "label.ai.chat": "Chat IA",

    # PLACEHOLDERS (15)
    "placeholder.search": "Buscar...",
    "placeholder.enter": "Ingresar...",
    "placeholder.select": "Seleccionar...",
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

    # ERRORS (8)
    "error.network": "Error de red",
    "error.invalid": "Entrada inválida",
    "error.required": "Campo obligatorio",
    "error.unknown": "Error desconocido",
    "error.invalid.coordinates": "Coordenadas inválidas",
    "error.check.updates": "Buscar Actualizaciones",
    "error.contact.support": "Por favor contacta con soporte si el problema persiste",
    "error.restart.app": "Reiniciar Aplicación",
    "error.retry": "Reintentar",

    # MOOD & JOURNAL (20)
    "mood.happy": "Feliz",
    "mood.sad": "Triste",
    "mood.excited": "Emocionado",
    "mood.calm": "Tranquilo",
    "mood.anxious": "Ansioso",
    "mood.angry": "Enojado",
    "mood.neutral": "Neutral",
    "mood.add.tags": "Añadir etiquetas",
    "journal.entry": "Entrada",
    "journal.new": "Nueva Entrada",

    # FRIENDS & CONTACTS (15)
    "friend.add": "Añadir Amigo",
    "friend.edit": "Editar Amigo",
    "friend.delete": "Eliminar Amigo",
    "friend.call": "Llamar",
    "friend.message": "Enviar Mensaje",
    "friend.notes": "Notas",
    "friend.history": "Historial",

    # GOALS & HABITS (15)
    "goal.title": "Objetivo",
    "goal.new": "Nuevo Objetivo",
    "goal.edit": "Editar Objetivo",
    "goal.delete": "Eliminar Objetivo",
    "goal.complete": "Completar Objetivo",
    "habit.title": "Hábito",
    "habit.new": "Nuevo Hábito",
    "habit.daily": "Diario",
    "habit.weekly": "Semanal",
    "habit.monthly": "Mensual",

    # COMMON WORDS (20)
    "common.save": "Guardar",
    "common.cancel": "Cancelar",
    "common.delete": "Eliminar",
    "common.edit": "Editar",
    "common.add": "Añadir",
    "common.remove": "Quitar",
    "common.search": "Buscar",
    "common.settings": "Configuración",
    "common.back": "Atrás",
    "common.next": "Siguiente",
    "common.done": "Listo",
    "common.close": "Cerrar",
    "common.yes": "Sí",
    "common.no": "No",
    "common.ok": "Aceptar",
}

def translate_file():
    """Translate Spanish localization file"""

    file_path = Path('LifeStyles/Resources/es.lproj/Localizable.strings')

    if not file_path.exists():
        print(f"❌ File not found: {file_path}")
        return

    print("🇪🇸 İspanyolca Çeviri Güncelleniyor...")
    print(f"📁 Dosya: {file_path}")
    print(f"📝 Çeviri sayısı: {len(TRANSLATIONS)}\n")

    # Read file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Track changes
    updated_count = 0
    not_found = []

    # Replace translations
    for key, translation in TRANSLATIONS.items():
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
                print(f"✅ {key} = \"{translation}\"")
        else:
            not_found.append(key)

    # Write updated file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    # Summary
    print(f"\n{'='*50}")
    print(f"🎉 Güncelleme Tamamlandı!")
    print(f"✅ Güncellenen: {updated_count}/{len(TRANSLATIONS)}")

    if not_found:
        print(f"\n⚠️  Bulunamayan key'ler ({len(not_found)}):")
        for key in not_found[:10]:
            print(f"   - {key}")
        if len(not_found) > 10:
            print(f"   ... ve {len(not_found) - 10} key daha")

    print(f"\n💡 Sonraki adım:")
    print(f"   git add {file_path}")
    print(f"   git commit -m \"chore: İspanyolca çeviri - İlk {updated_count} key\"")

if __name__ == '__main__':
    translate_file()
