![Banner](assets/images/banner.png)

# 🚀 My Tracking App

> Applicazione Flutter per tracciare l’utilizzo quotidiano di uno o più prodotti, monitorare costi e tempo perso stimato, gestire il residuo della confezione e avere un accesso rapido da widget Android.

## ✨ Funzionalità principali

- 📦 Tracking multi-prodotto, con selettore compatto del prodotto in uso
- 📊 Home con conteggio giornaliero, scorta, costi e ultimi 7 giorni
- 📈 Cronologia raggruppata per giorni, settimane e mesi, con grafici e statistiche
- ↩️ Annulla dopo ogni registrazione e ogni cancellazione
- 🏆 Obiettivi e badge sbloccabili
- 📉 Piano di riduzione **indipendente per ogni prodotto**
- ⚙️ Impostazioni con una pagina per ogni prodotto, anche quando non è in uso
- 🗄️ Archiviazione dei prodotti con storico conservato
- 📄 Backup ed export in CSV
- 📲 Widget Home Android responsive con layout **small**, **medium** e **large**
- 🔔 Promemoria periodici, proposti già alla prima configurazione
- 🎨 Tema **scuro / chiaro / sistema**
- 🔒 Dati salvati localmente sul dispositivo

---

## 🔔 Sistema notifiche

L’app supporta promemoria periodici globali di registrazione con i seguenti intervalli:

- 30 minuti
- 1 ora
- 2 ore
- 4 ore
- 8 ore
- 12 ore

Le notifiche sono gestite su Android tramite:

- `flutter_local_notifications`
- `workmanager`

---

## 🛠️ Piattaforme

- 🤖 **Android**: piattaforma prioritaria
- 🖥️ **Windows**: supporto utile per debug e test locali

---

## 🔒 Setup locale

Prerequisiti, con le versioni su cui la build è verificata:

- Flutter **3.47.5** stable (Dart 3.13.4)
- Android SDK con platform **android-36**, build-tools 36.0.0 e NDK 28.2.13676358
- **JDK 21** — Gradle 8.14.5 non supporta JDK 25, quindi va agganciato con
  `flutter config --jdk-dir "<percorso del JDK 21>"`
- Visual Studio Code

La catena di build usa Gradle 8.14.5, AGP 8.13.2 e Kotlin 2.2.21, volutamente
entro la linea 8.x di AGP.

`android/gradle.properties` dimensiona il daemon Gradle a 2 GB di heap: su
macchine con poca RAM valori più alti fanno terminare il daemon a metà build.

---

## ⚡ Installazione rapida PC

Se vuoi compilare il progetto localmente:

### 1. Clona la repository
```bash
git clone https://github.com/lorenzocaputodev/my_tracking_app.git
cd my_tracking_app
```

### 2. Installa le dipendenze
```bash
flutter pub get
```

### 3. Genera le icone ufficiali
```bash
dart run flutter_launcher_icons
```

### 4. Avvia l’app
```bash
flutter run
```

---

## 📂 Struttura essenziale

- `lib/models/` → modelli dati
- `lib/providers/` → stato applicativo e persistenza
- `lib/screens/` → schermate principali
- `lib/widgets/` → componenti UI riutilizzabili
- `lib/theme/` → token di design, temi e decorazioni
- `lib/utils/` → utility, bridge e formattazione
- `android/app/src/main/kotlin/com/example/my_tracking_app/widget/` → implementazione nativa del widget Android

---

## 🔐 Privacy e dati

- Nessun account richiesto
- Nessun backend obbligatorio
- Dati salvati localmente sul dispositivo

---

## 👨‍💻 Sviluppo

Durante sviluppo, debugging e rifinitura del progetto è stato utilizzato supporto AI come assistenza tecnica per troubleshooting, revisione della documentazione, verifica di problemi tecnici e supporto alla scrittura e pulizia del codice.

---

## 👤 Autore

**Lorenzo Caputo**  
GitHub: [lorenzocaputodev](https://github.com/lorenzocaputodev)
