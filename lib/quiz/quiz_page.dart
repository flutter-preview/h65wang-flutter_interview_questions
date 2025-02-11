import 'package:flutter/material.dart';
import 'package:flutter_interview_questions/model/quiz_model.dart';
import 'package:flutter_interview_questions/result/result_page.dart';

const _kOverviewItemWidth = 56.0;
const _kAnimationDuration = Duration(milliseconds: 800);
const _kAnimationCurve = Curves.easeOutCirc;

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final _pageController = PageController();
  late final _overviewScrollController = ScrollController();

  bool _pageAnimating = false;

  @override
  void dispose() {
    _pageController.dispose();
    _overviewScrollController.dispose();
    super.dispose();
  }

  void _updateOverviewPosition(int pageNum) {
    if (_pageAnimating) return;
    _overviewScrollController.animateTo(
      _kOverviewItemWidth * pageNum,
      duration: _kAnimationDuration,
      curve: _kAnimationCurve,
    );
  }

  void _animateToPage(int index) {
    _updateOverviewPosition(index);
    _pageAnimating = true;
    _pageController
        .animateToPage(
          index,
          duration: _kAnimationDuration,
          curve: _kAnimationCurve,
        )
        .then((value) => _pageAnimating = false);
  }

  @override
  Widget build(BuildContext context) {
    final quizItems = context.read<QuizModel>().quizItems;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Quiz Page'),
      ),
      body: quizItems.isEmpty
          ? const Center(
              child: Text(
                'There are no matching questions in the question bank',
              ),
            )
          : Column(
              children: [
                _Overview(
                  scrollController: _overviewScrollController,
                  onTap: _animateToPage,
                ),
                const Divider(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: quizItems.length,
                    itemBuilder: (_, int index) => _PageItem(
                      index,
                      onTap: () => {
                              if (index < quizItems.length - 1){
                                  _pageController.nextPage(
                                      duration: _kAnimationDuration,
                                      curve: _kAnimationCurve),
                                }
                            }),
                    onPageChanged: _updateOverviewPosition,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Submit',
        child: const Icon(Icons.done),
        onPressed: () async {
          final navigator = Navigator.of(context);
          var completed = quizItems.every((item) => item.answered);

          if (!completed) {
            completed = (await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          content: const Text(
                              'You are missing some answers, continue?'),
                          actions: [
                            TextButton(
                                onPressed: Navigator.of(context).pop,
                                child: const Text('no')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('yes')),
                          ],
                        )) ==
                true);
          }
          if (!completed) return;

          navigator.push(
            MaterialPageRoute(builder: (_) => const ResultPage()),
          );
        },
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({Key? key, required this.scrollController, this.onTap})
      : super(key: key);

  final void Function(int index)? onTap;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final quizItems = context.read<QuizModel>().quizItems;
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        itemCount: quizItems.length,
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          width: _kOverviewItemWidth,
          height: 40,
          child: ValueListenableBuilder(
            valueListenable: quizItems[index],
            builder: (context, _, child) {
              return _OverviewItem(
                index: index,
                isAnswered: quizItems[index].answered,
                onTap: () => onTap?.call(index),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem(
      {required this.index, required this.isAnswered, this.onTap});
  final int index;
  final bool isAnswered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: onTap,
      shape: CircleBorder(
          side: BorderSide(
              color: isAnswered ? Colors.green : const Color(0xFF000000))),
      child: Text('$index'),
    );
  }
}

class _PageItem extends StatelessWidget {
  const _PageItem(this.index, {Key? key, this.onTap}) : super(key: key);
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = context.read<QuizModel>().quizItems[index];
    return ValueListenableBuilder(
      valueListenable: item,
      builder: (context, choices, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child!,
            const Divider(),
            for (final choice in choices)
              ListTile(
                title: Text(choice.content),
                selected: choice.selected,
                selectedColor: Colors.black,
                selectedTileColor: Colors.green.shade200,
                onTap: () {
                  item.radioChoose(choice);
                  onTap?.call();
                },
              ),
          ],
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(item.question.title,style: const TextStyle(fontSize: 16),),
      ),
    );
  }
}
