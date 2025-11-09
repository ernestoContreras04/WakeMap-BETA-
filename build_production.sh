#!/bin/bash

# Script para construir la aplicación para producción (Play Store)
# Este script configura la API key de Gemini automáticamente

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Script de Build para Producción - WakeMap${NC}"
echo ""

# Verificar que la API key esté configurada
if [ -z "$GEMINI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  Advertencia: Variable GEMINI_API_KEY no está configurada${NC}"
    echo ""
    echo "Por favor, configura tu API key de Gemini:"
    echo "  export GEMINI_API_KEY=tu_clave_aqui"
    echo ""
    echo "O pásala directamente al script:"
    echo "  GEMINI_API_KEY=tu_clave ./build_production.sh"
    echo ""
    read -p "¿Deseas continuar sin API key? (s/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${RED}❌ Build cancelado${NC}"
        exit 1
    fi
fi

# Verificar que Flutter esté instalado
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter no está instalado o no está en el PATH${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Iniciando build de producción...${NC}"
echo ""

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Obtener dependencias
echo "📥 Obteniendo dependencias..."
flutter pub get

# Build para Android (APK)
echo ""
echo -e "${GREEN}📱 Construyendo APK para Android...${NC}"
if [ -z "$GEMINI_API_KEY" ]; then
    flutter build apk --release
else
    flutter build apk --release --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
fi

# Build para Android (App Bundle - para Play Store)
echo ""
echo -e "${GREEN}📦 Construyendo App Bundle para Play Store...${NC}"
if [ -z "$GEMINI_API_KEY" ]; then
    flutter build appbundle --release
else
    flutter build appbundle --release --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
fi

echo ""
echo -e "${GREEN}✅ Build completado exitosamente!${NC}"
echo ""
echo "📁 Archivos generados:"
echo "  - APK: build/app/outputs/flutter-apk/app-release.apk"
echo "  - App Bundle: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo -e "${YELLOW}⚠️  Recuerda:${NC}"
echo "  1. Firmar el APK/App Bundle antes de subirlo a Play Store"
echo "  2. Verificar que la API key esté correctamente configurada"
echo "  3. Probar la app antes de publicar"

