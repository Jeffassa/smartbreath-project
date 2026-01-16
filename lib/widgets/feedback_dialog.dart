class FeedbackWidget extends StatelessWidget {
  final int dataId;
  FeedbackWidget({required this.dataId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Alerte de santé"),
      content: Text("L'IA remarque une anomalie. Comment vous sentez-vous ?"),
      actions: [
        ElevatedButton(
          onPressed: () {
            ApiService().sendFeedback(dataId, 0, "Fausse alerte");
            Navigator.pop(context);
          },
          child: Text("Je vais bien"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            ApiService().sendFeedback(dataId, 1, "Crise confirmée");
            Navigator.pop(context);
          },
          child: Text("Je me sens mal"),
        ),
      ],
    );
  }
}