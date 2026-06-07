# Анализ моделей для классификации sleep intents

## Русская версия

В этом проекте был проведён набор экспериментов по классификации коротких пользовательских сообщений, связанных со сном. Основная задача заключалась в выборе модели, которая хорошо работает не только на стандартном test split, но и на более реалистичных формулировках, близких к живым пользовательским запросам.

Для обучения использовался датасет `sleep_intents_seed.csv` с 798 размеченными примерами и 6 классами. Для финальной проверки был подготовлен отдельный holdout-набор `sleep_intents_holdout.csv` из 72 примеров. Он не участвовал ни в обучении, ни в подборе параметров и использовался как основной ориентир при выборе итоговой модели.

### Данные и схема экспериментов

| Параметр | Значение |
|---|---:|
| Исходный датасет | `sleep_intents_seed.csv` |
| Размер датасета | 798 примеров |
| Число классов | 6 |
| Баланс классов | примерно по 133 примера на класс |
| Holdout-набор | `sleep_intents_holdout.csv` |
| Размер holdout | 72 примера |
| Train/test split | стратифицированный `train_test_split` |
| `test_size` | `0.2` |
| `random_state` | `2022` |

Для части моделей применялась предобработка текста через spaCy `ru_core_news_lg`. В базовом варианте выполнялись лемматизация и удаление пунктуации. В одном из вариантов дополнительно удалялись стоп-слова. Также отдельно проверялся вариант, в котором стоп-слова сохранялись, но текст всё равно проходил лемматизацию и очистку от пунктуации.

### Соглашение об именах моделей

| Элемент имени | Значение |
|---|---|
| `p` в начале | применялся `preprocess`: лемматизация, удаление стоп-слов и пунктуации |
| `n` перед `_` | применялся `preprocess_new`: лемматизация и удаление пунктуации, стоп-слова сохранялись |
| `T` в конце | векторизация через `TfidfVectorizer` |
| без `T` | векторизация через `CountVectorizer` |
| `1` | униграммы |
| `2` | биграммы (`ngram_range=(1, 2)`) |
| `3` | триграммы (`ngram_range=(1, 3)`) |
| `NB` | `MultinomialNB` |
| `KNE` | `KNeighborsClassifier`, `metric='euclidean'`, `n_neighbors=10` |
| `KNC` | `KNeighborsClassifier`, `metric='cosine'`, `n_neighbors=10` |
| `RF` | `RandomForestClassifier` |
| `clf_` | обучение на исходном тексте без препроцессинга |

Пример: `clf_NB2` — это `MultinomialNB` + `CountVectorizer` с биграммами без предварительной обработки текста.

### Общий результат по всем конфигурациям

Всего было протестировано 48 конфигураций. Лучший результат на holdout показала модель `clf_NB2`.

| Модель | Векторизация | Препроцессинг | Accuracy | Macro F1 | Weighted F1 | Ошибок на holdout |
|---|---|---|---:|---:|---:|---:|
| `clf_NB2` | `CountVectorizer(1,2)` | нет | `0.9722` | `0.9727` | `0.9727` | 2 |
| `clf_NB3` | `CountVectorizer(1,3)` | нет | `0.9722` | `0.9727` | `0.9727` | 2 |
| `clf_NB1T` | `TfidfVectorizer(1)` | нет | `0.9722` | `0.9727` | `0.9727` | 2 |
| `clf_NB1` | `CountVectorizer(1)` | нет | `0.9583` | `0.9581` | `0.9581` | 3 |
| `clf_KNC1` | `CountVectorizer(1)` | нет | `0.9583` | `0.9581` | `0.9581` | 3 |
| `clf_KNC1T` | `TfidfVectorizer(1)` | нет | `0.9583` | `0.9581` | `0.9581` | 3 |
| `clf_KNC2` | `CountVectorizer(1,2)` | нет | `0.9444` | `0.9435` | `0.9435` | 4 |
| `clf_KNC3` | `CountVectorizer(1,3)` | нет | `0.9444` | `0.9435` | `0.9435` | 4 |
| `clf_RF1` | `CountVectorizer(1)` | нет | `0.9306` | `0.9289` | `0.9289` | 5 |
| `clf_KNE1T` | `TfidfVectorizer(1)` | нет | `0.9167` | `0.9161` | `0.9161` | 6 |
| `clf_RF2` | `CountVectorizer(1,2)` | нет | `0.9028` | `0.9008` | `0.9008` | 7 |
| `clf_RF3` | `CountVectorizer(1,3)` | нет | `0.8889` | `0.8857` | `0.8857` | 8 |
| `clf_RF1T` | `TfidfVectorizer(1)` | нет | `0.8889` | `0.8856` | `0.8856` | 8 |
| `pclfn_NB3` | `CountVectorizer(1,3)` | `preprocess_new` | `0.8750` | `0.8731` | `0.8731` | 9 |
| `pclfn_NB1T` | `TfidfVectorizer(1)` | `preprocess_new` | `0.8750` | `0.8731` | `0.8731` | 9 |

Полный список всех 48 моделей зафиксирован в `models/тесты.txt` (строки 1331–1379).

### Лучшая модель: `clf_NB2`

Итоговый baseline оказался простым: `MultinomialNB` на биграммах без препроцессинга текста.

| Метрика | Значение |
|---|---:|
| Accuracy | `0.9722` |
| Macro F1 | `0.9727` |
| Weighted F1 | `0.9727` |
| Ошибок на holdout | `2 из 72` |

#### Classification report для `clf_NB2`

| Класс | Precision | Recall | F1 | Support |
|---|---:|---:|---:|---:|
| `insomnia_now` | `1.0000` | `0.9167` | `0.9565` | 12 |
| `sleep_duration_report` | `1.0000` | `1.0000` | `1.0000` | 12 |
| `sleep_schedule_report` | `0.8571` | `1.0000` | `0.9231` | 12 |
| `welcome` | `1.0000` | `1.0000` | `1.0000` | 12 |
| `other` | `1.0000` | `0.9167` | `0.9565` | 12 |
| `goodbye` | `1.0000` | `1.0000` | `1.0000` | 12 |

#### Ошибки модели `clf_NB2` на holdout

| Текст | Истинный класс | Предсказание |
|---|---|---|
| проснулся среди ночи и больше не уснул | `insomnia_now` | `sleep_schedule_report` |
| подскажи рецепт омлета | `other` | `sleep_schedule_report` |

Обе ошибки связаны с тем, что модель слишком часто относит фразы к классу `sleep_schedule_report`, если в тексте есть временные маркеры или нейтральный бытовой контекст.

### Сравнение по типам векторизации и препроцессинга

#### CountVectorizer

| Конфигурация | Лучшая модель | Accuracy | Macro F1 | Weighted F1 | Ошибок |
|---|---|---:|---:|---:|---:|
| Без препроцессинга | `clf_NB2` | `0.9722` | `0.9727` | `0.9727` | 2 |
| `preprocess` | `pclf_KNC2` | `0.7083` | `0.7048` | `0.7048` | 21 |
| `preprocess_new` | `pclfn_NB3` | `0.8750` | `0.8731` | `0.8731` | 9 |

#### TfidfVectorizer

| Конфигурация | Лучшая модель | Accuracy | Macro F1 | Weighted F1 | Ошибок |
|---|---|---|---:|---:|---:|
| Без препроцессинга | `clf_NB1T` | `0.9722` | `0.9727` | `0.9727` | 2 |
| `preprocess` | `pclf_NB1T` | `0.6806` | `0.6582` | `0.6582` | 23 |
| `preprocess_new` | `pclfn_NB1T` | `0.8750` | `0.8731` | `0.8731` | 9 |

### Топ-15 моделей по качеству на holdout

| # | Модель | Accuracy | Macro F1 | Weighted F1 |
|---:|---|---:|---:|---:|
| 1 | `clf_NB2` | `0.9722` | `0.9727` | `0.9727` |
| 2 | `clf_NB3` | `0.9722` | `0.9727` | `0.9727` |
| 3 | `clf_NB1T` | `0.9722` | `0.9727` | `0.9727` |
| 4 | `clf_NB1` | `0.9583` | `0.9581` | `0.9581` |
| 5 | `clf_KNC1` | `0.9583` | `0.9581` | `0.9581` |
| 6 | `clf_KNC1T` | `0.9583` | `0.9581` | `0.9581` |
| 7 | `clf_KNC2` | `0.9444` | `0.9435` | `0.9435` |
| 8 | `clf_KNC3` | `0.9444` | `0.9435` | `0.9435` |
| 9 | `clf_RF1` | `0.9306` | `0.9289` | `0.9289` |
| 10 | `clf_KNE1T` | `0.9167` | `0.9161` | `0.9161` |
| 11 | `clf_RF2` | `0.9028` | `0.9008` | `0.9008` |
| 12 | `clf_RF3` | `0.8889` | `0.8857` | `0.8857` |
| 13 | `clf_RF1T` | `0.8889` | `0.8856` | `0.8856` |
| 14 | `pclfn_NB3` | `0.8750` | `0.8731` | `0.8731` |
| 15 | `pclfn_NB1T` | `0.8750` | `0.8731` | `0.8731` |

### Основные наблюдения

| Наблюдение | Вывод |
|---|---|
| Предобработка | в этой задаче не помогла и часто ухудшала качество |
| Test split | был слишком оптимистичным и не отражал реальное качество |
| Лучший класс моделей | `MultinomialNB` на bag-of-words признаках |
| KNN | cosine distance работал лучше euclidean |
| Основной источник ошибок | путаница вокруг `sleep_schedule_report` |
| Слабое место | класс `other`, особенно на off-topic фразах |

### Практический вывод

На текущем этапе наиболее рациональным baseline является `clf_NB2`, то есть `Pipeline(CountVectorizer(ngram_range=(1, 2)), MultinomialNB())` на исходном тексте без spaCy-препроцессинга. Модель проста, быстро работает на инференсе и показывает лучший результат на holdout среди всех протестированных конфигураций.

---

## English version

This project includes a set of experiments for classifying short user messages related to sleep. The main goal was not just to get strong results on a standard test split, but to find a model that also performs well on more natural user phrasing.

The training dataset was `sleep_intents_seed.csv` with 798 labeled examples and 6 classes. A separate holdout set, `sleep_intents_holdout.csv`, contained 72 examples and was not used during training or tuning. It served as the main benchmark for the final model choice.

### Data and experiment setup

| Parameter | Value |
|---|---:|
| Source dataset | `sleep_intents_seed.csv` |
| Dataset size | 798 examples |
| Number of classes | 6 |
| Class balance | about 133 examples per class |
| Holdout set | `sleep_intents_holdout.csv` |
| Holdout size | 72 examples |
| Train/test split | stratified `train_test_split` |
| `test_size` | `0.2` |
| `random_state` | `2022` |

For some models, text preprocessing was applied with spaCy `ru_core_news_lg`. The baseline variant used lemmatization and punctuation removal. One variant also removed stop words. Another variant kept stop words while still applying lemmatization and punctuation cleanup.

### Model naming convention

| Name part | Meaning |
|---|---|
| leading `p` | `preprocess` applied: lemmatization, stop-word removal, punctuation removal |
| `n` before `_` | `preprocess_new` applied: lemmatization and punctuation removal, stop words kept |
| trailing `T` | `TfidfVectorizer` |
| no `T` | `CountVectorizer` |
| `1` | unigrams |
| `2` | bigrams (`ngram_range=(1, 2)`) |
| `3` | trigrams (`ngram_range=(1, 3)`) |
| `NB` | `MultinomialNB` |
| `KNE` | `KNeighborsClassifier`, `metric='euclidean'`, `n_neighbors=10` |
| `KNC` | `KNeighborsClassifier`, `metric='cosine'`, `n_neighbors=10` |
| `RF` | `RandomForestClassifier` |
| `clf_` | raw text, no preprocessing |

Example: `clf_NB2` means `MultinomialNB` + `CountVectorizer` with bigrams, trained on raw text.

### Overall result across all configurations

A total of 48 configurations were tested. The best holdout result was achieved by `clf_NB2`.

| Model | Vectorization | Preprocessing | Accuracy | Macro F1 | Weighted F1 | Holdout errors |
|---|---|---|---:|---:|---:|---:|
| `clf_NB2` | `CountVectorizer(1,2)` | none | `0.9722` | `0.9727` | `0.9727` | 2 |
| `clf_NB3` | `CountVectorizer(1,3)` | none | `0.9722` | `0.9727` | `0.9727` | 2 |
| `clf_NB1T` | `TfidfVectorizer(1)` | none | `0.9722` | `0.9727` | `0.9727` | 2 |
| `clf_NB1` | `CountVectorizer(1)` | none | `0.9583` | `0.9581` | `0.9581` | 3 |
| `clf_KNC1` | `CountVectorizer(1)` | none | `0.9583` | `0.9581` | `0.9581` | 3 |
| `clf_KNC1T` | `TfidfVectorizer(1)` | none | `0.9583` | `0.9581` | `0.9581` | 3 |
| `clf_KNC2` | `CountVectorizer(1,2)` | none | `0.9444` | `0.9435` | `0.9435` | 4 |
| `clf_KNC3` | `CountVectorizer(1,3)` | none | `0.9444` | `0.9435` | `0.9435` | 4 |
| `clf_RF1` | `CountVectorizer(1)` | none | `0.9306` | `0.9289` | `0.9289` | 5 |
| `clf_KNE1T` | `TfidfVectorizer(1)` | none | `0.9167` | `0.9161` | `0.9161` | 6 |
| `clf_RF2` | `CountVectorizer(1,2)` | none | `0.9028` | `0.9008` | `0.9008` | 7 |
| `clf_RF3` | `CountVectorizer(1,3)` | none | `0.8889` | `0.8857` | `0.8857` | 8 |
| `clf_RF1T` | `TfidfVectorizer(1)` | none | `0.8889` | `0.8856` | `0.8856` | 8 |
| `pclfn_NB3` | `CountVectorizer(1,3)` | `preprocess_new` | `0.8750` | `0.8731` | `0.8731` | 9 |
| `pclfn_NB1T` | `TfidfVectorizer(1)` | `preprocess_new` | `0.8750` | `0.8731` | `0.8731` | 9 |

The full list of all 48 models is stored in `models/тесты.txt` (lines 1331–1379).

### Best model: `clf_NB2`

The final baseline was simple: `MultinomialNB` on bigram features without text preprocessing.

| Metric | Value |
|---|---:|
| Accuracy | `0.9722` |
| Macro F1 | `0.9727` |
| Weighted F1 | `0.9727` |
| Holdout errors | `2 / 72` |

#### Classification report for `clf_NB2`

| Class | Precision | Recall | F1 | Support |
|---|---:|---:|---:|---:|
| `insomnia_now` | `1.0000` | `0.9167` | `0.9565` | 12 |
| `sleep_duration_report` | `1.0000` | `1.0000` | `1.0000` | 12 |
| `sleep_schedule_report` | `0.8571` | `1.0000` | `0.9231` | 12 |
| `welcome` | `1.0000` | `1.0000` | `1.0000` | 12 |
| `other` | `1.0000` | `0.9167` | `0.9565` | 12 |
| `goodbye` | `1.0000` | `1.0000` | `1.0000` | 12 |

#### Holdout errors for `clf_NB2`

| Text | True class | Prediction |
|---|---|---|
| проснулся среди ночи и больше не уснул | `insomnia_now` | `sleep_schedule_report` |
| подскажи рецепт омлета | `other` | `sleep_schedule_report` |

Both mistakes come from the model overassigning phrases to `sleep_schedule_report` when temporal markers or neutral everyday context are present.

### Comparison by vectorization and preprocessing

#### CountVectorizer

| Configuration | Best model | Accuracy | Macro F1 | Weighted F1 | Errors |
|---|---|---:|---:|---:|---:|
| Raw text | `clf_NB2` | `0.9722` | `0.9727` | `0.9727` | 2 |
| `preprocess` | `pclf_KNC2` | `0.7083` | `0.7048` | `0.7048` | 21 |
| `preprocess_new` | `pclfn_NB3` | `0.8750` | `0.8731` | `0.8731` | 9 |

#### TfidfVectorizer

| Configuration | Best model | Accuracy | Macro F1 | Weighted F1 | Errors |
|---|---|---|---:|---:|---:|
| Raw text | `clf_NB1T` | `0.9722` | `0.9727` | `0.9727` | 2 |
| `preprocess` | `pclf_NB1T` | `0.6806` | `0.6582` | `0.6582` | 23 |
| `preprocess_new` | `pclfn_NB1T` | `0.8750` | `0.8731` | `0.8731` | 9 |

### Top 15 models by holdout quality

| # | Model | Accuracy | Macro F1 | Weighted F1 |
|---:|---|---:|---:|---:|
| 1 | `clf_NB2` | `0.9722` | `0.9727` | `0.9727` |
| 2 | `clf_NB3` | `0.9722` | `0.9727` | `0.9727` |
| 3 | `clf_NB1T` | `0.9722` | `0.9727` | `0.9727` |
| 4 | `clf_NB1` | `0.9583` | `0.9581` | `0.9581` |
| 5 | `clf_KNC1` | `0.9583` | `0.9581` | `0.9581` |
| 6 | `clf_KNC1T` | `0.9583` | `0.9581` | `0.9581` |
| 7 | `clf_KNC2` | `0.9444` | `0.9435` | `0.9435` |
| 8 | `clf_KNC3` | `0.9444` | `0.9435` | `0.9435` |
| 9 | `clf_RF1` | `0.9306` | `0.9289` | `0.9289` |
| 10 | `clf_KNE1T` | `0.9167` | `0.9161` | `0.9161` |
| 11 | `clf_RF2` | `0.9028` | `0.9008` | `0.9008` |
| 12 | `clf_RF3` | `0.8889` | `0.8857` | `0.8857` |
| 13 | `clf_RF1T` | `0.8889` | `0.8856` | `0.8856` |
| 14 | `pclfn_NB3` | `0.8750` | `0.8731` | `0.8731` |
| 15 | `pclfn_NB1T` | `0.8750` | `0.8731` | `0.8731` |

### Main observations

| Observation | Conclusion |
|---|---|
| Preprocessing | did not help and often reduced quality |
| Standard test split | was too optimistic and did not reflect real performance |
| Best classifier family | `MultinomialNB` with bag-of-words features |
| KNN | cosine distance outperformed euclidean distance |
| Main source of errors | confusion around `sleep_schedule_report` |
| Weak point | class `other`, especially off-topic phrases |

### Practical takeaway

For this task, the most reasonable baseline is `clf_NB2`, i.e. `Pipeline(CountVectorizer(ngram_range=(1, 2)), MultinomialNB())` trained on raw text without spaCy preprocessing. The model is simple, fast at inference, and gives the best holdout performance among all tested configurations.

Further improvements should focus not on heavier preprocessing, but on expanding the holdout set, refining ambiguous classes, and using `predict_proba` with a confidence threshold when needed.