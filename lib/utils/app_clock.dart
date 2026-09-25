/// Ora corrente dell'app. I golden test la fissano, così le scene che
/// dipendono dal giorno della settimana restano uguali ogni giorno.
DateTime Function() appNow = DateTime.now;
