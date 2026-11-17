/// Statistika jednoho studijního dne.
class DayStat {
  final int day; // číslo studijního dne (viz Scheduler.studyDayNumber)
  final DateTime date; // kalendářní datum dne (UTC půlnoc, jen pro popisky)
  final int reviewed; // zopakováno
  final int learned; // nově naučeno

  const DayStat(this.day, this.date, this.reviewed, this.learned);

  int get total => reviewed + learned;
}
