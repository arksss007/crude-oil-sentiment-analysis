## ------------------------------------------------------------------------
library(knitr)  # Export R Notebook to R Script
library(qdap)  # Quantitative Discourse Analysis Package
library(RCurl)  # For HTTP Requests
library(stringr)  # For String Manipulation
library(tidytext)  # Natural Language Processing package in R
library(tidyverse)  # For data wrangling
library(tm)  # Text Mining
library(twitteR)  # To connect to the Twitter API
library(wordcloud)  # Generation of Word Clouds


## ------------------------------------------------------------------------
# Store the required API keys for connection to Twitter
api_key <- "hBgUhFxipyNt2JT87QEGuV1Ok"
api_secret <- "kEkWlcKIC1nHamXMHOrYzZzsevGtnZ26j1XggoannDcvESRx9J"
access_token <- "898901988754153472-boY81BSVy95r26As36rYxzNX63C6ibl"
access_token_secret <- "obKPRXeSx6UiLUCQoirN95G2zt66TWepMbKQ032mzZFzL"

# Authenticate against the Twitter API
setup_twitter_oauth(api_key, api_secret, access_token, access_token_secret)

## ------------------------------------------------------------------------
# Query tweets related to "#crudeoil"
crude_tweets <- searchTwitter(searchString = "#crudeoil", n = 1000, lang = "en")

# Examine the crude_tweets object
head(crude_tweets)


## ------------------------------------------------------------------------
# Convert the raw queried data into a data.frame object
crude_df <- twListToDF(crude_tweets)

# Examine the data.frame object
str(crude_df)
View(crude_df)


## ------------------------------------------------------------------------
# Remove all preceding "RT" characters in Retweeted tweets
crude_df$text <- gsub(pattern = "RT", replacement = "", crude_df$text)

# Remove all Twitter user handles in Retweets
crude_df$text <- gsub(pattern = "@\\w+", replacement = "", crude_df$text)

# Convert all tweets to lower case
crude_df$text <- tolower(crude_df$text)

# Remove punctuation
crude_df$text <- removePunctuation(crude_df$text)

# Remove quotation marks
crude_df$text <- gsub(pattern = '“', replacement = "", crude_df$text)

# Remove URL links
crude_df$text <- gsub("http\\w+", "", crude_df$text)

# Replace contractions
crude_df$text <- replace_contraction(crude_df$text)

# Examine the cleaned text data
crude_df$text[1:10]


## ------------------------------------------------------------------------
# Define a list of uninformative stop-words for removal
crude_stopwords <- c("crudeoil", "Crudeoil", "crude", "oil", "oott", stopwords("en"))

# Remove all stop words
crude_df$text <- removeWords(crude_df$text, crude_stopwords)

# Remove all whitespace
crude_df$text <- stripWhitespace(crude_df$text)

# Examine the text data without stop words
crude_df$text[1:10]


## ------------------------------------------------------------------------
# Explore the most common words in the data set
crude_df %>%
  unnest_tokens(word, text) %>%
  group_by(word) %>%
  count() %>%
  arrange(desc(n)) %>%
  head(n = 10) %>%
  ggplot(mapping = aes(x = reorder(word, desc(n)), y = n, fill = word)) +
    geom_col() +
    labs(
      title = "Word Frequency in #crudeoil tweets",
      subtitle = "As of 23rd June 2019",
      x = "Word",
      y = "Frequency"
    ) +
    theme(legend.position = "none")


## ------------------------------------------------------------------------
# Generate a simple word cloud on the Twitter data
wordcloud(
  words = crude_df$text, 
  min.freq = 15, 
  colors = brewer.pal(8, "Dark2"), 
  random.color = TRUE, 
  max.words = 250
  )


## ------------------------------------------------------------------------
# Define a Polarity Object for the set of #crudeoil tweets
crude_polarity <- polarity(crude_df$text)

# Print a summary of the polarity object
summary(crude_polarity$all$polarity)


## ------------------------------------------------------------------------
# Visualize the polarity object with ggplot
ggplot(crude_polarity$all, aes(x = polarity, y = ..density..)) +
  geom_histogram(binwidth = 0.25, fill = "#bada55", colour = "grey60") +
  geom_density(color = "darkblue") +
  labs(
    title = "qdap Polarity Scores of #crudeoil tweets",
    subtitle = "As of 23rd June 2019",
    x = "Polarity Score",
    y = "Frequency"
  )


## ------------------------------------------------------------------------
# Store a character vector containing all tweets
tweet_vector <- crude_df$text

# Examine the vector
str(tweet_vector)
head(tweet_vector)
tail(tweet_vector)


## ------------------------------------------------------------------------
# Convert the character vector into a Volatilte Corpus
tweet_corpus <- VCorpus(VectorSource(tweet_vector))

# Convert the corpus into a Document Term Matrix
tweet_dtm <- DocumentTermMatrix(tweet_corpus)
tweet_dtm_matrix <- as.matrix(tweet_dtm)

# Examine the Document Term Matrix
str(tweet_dtm_matrix)


## ------------------------------------------------------------------------
# Tidy the Document Term Matrix for tidytext analysis
tidy_tweets <- tidy(tweet_dtm)

# Examine the tidied dataset
str(tidy_tweets)
head(tidy_tweets)
tail(tidy_tweets)


## ------------------------------------------------------------------------
# Store the "Bing" lexicon from tidytext
bing <- get_sentiments(lexicon = "bing")

# Inner join the Bing lexicon to the Document Term Matrix and generate a Polarity Score
tweet_polarity_bing <-
  tidy_tweets %>% 
  inner_join(bing, by = c("term" = "word")) %>% 
  mutate(index = as.numeric(document)) %>% 
  count(sentiment, index) %>% 
  spread(sentiment, n, fill = 0) %>% 
  mutate(polarity = positive - negative)

# Examine the mutated dataset
str(tweet_polarity_bing)
head(tweet_polarity_bing)


## ------------------------------------------------------------------------
# Plot Polarity Scores against Index
ggplot(data = tweet_polarity_bing, aes(rev(index), polarity)) +
  geom_smooth() +
  labs(
    title = "Polarity of #CrudeOil tweets (With Bing Lexicon)",
    subtitle = "From 19 June to 23 June 2019",
    x = "Time",
    y = "Polarity"
  )


## ------------------------------------------------------------------------
# Store the "AFINN" lexicon from tidytext
afinn <- get_sentiments(lexicon = "afinn")

# Inner join the AFINN lexicon to the Document Term Matrix and generate a Polarity Score
tweet_polarity_afinn <-
  tidy_tweets %>% 
  inner_join(afinn, by = c("term" = "word")) %>% 
  mutate(index = as.numeric(document)) %>%
  count(value, index) %>% 
  group_by(index) %>% 
  summarize(polarity = sum(value * n))

# Examine the mutated dataset
str(tweet_polarity_afinn)
head(tweet_polarity_afinn)


## ------------------------------------------------------------------------
# Plot Polarity Scores against Index
ggplot(data = tweet_polarity_afinn, aes(rev(index), polarity)) +
  geom_smooth() +
  labs(
    title = "Polarity of #CrudeOil tweets (With AFINN Lexicon)",
    subtitle = "From 19 June to 23 June 2019",
    x = "Time",
    y = "Polarity"
  )


## ------------------------------------------------------------------------
# Store the "Loughran-Macdonald" Sentiment Lexicon from tidytext
loughran <- get_sentiments(lexicon = "loughran")

# Inner join the Bing lexicon to the Document Term Matrix and generate a Polarity Score
tweet_polarity_loughran <-
  tidy_tweets %>% 
  inner_join(loughran, by = c("term" = "word")) %>% 
  mutate(index = as.numeric(document)) %>% 
  group_by(sentiment) %>% 
  summarize(count = sum(count))

# Examine the mutated dataset
str(tweet_polarity_loughran)
head(tweet_polarity_loughran)


## ------------------------------------------------------------------------
# Plot a distribution of sentiments
ggplot(tweet_polarity_loughran, aes(x = reorder(sentiment, desc(count)), y = count, fill = sentiment)) +
  geom_col() +
  labs(
    title = "Polarity of #CrudeOil tweets (With Loughran-Macdonald Lexicon)",
    subtitle = "From 19 June to 23 June 2019",
    x = "Sentiment",
    y = "Count"
  ) +
  theme(legend.position = "none")


## ------------------------------------------------------------------------
# Extract all "positive-sentiment" tweets and collapse into a single string
pos_terms <-
  crude_df %>% 
  mutate(polarity = polarity(text)$all$polarity) %>% 
  filter(polarity > 0) %>% 
  pull(text) %>% 
  paste(collapse = " ")

# View the joined string
substr(pos_terms, 1, 100)


## ------------------------------------------------------------------------
# Extract all "negative-sentiment" tweets and collapse into a single string
neg_terms <-
  crude_df %>% 
  mutate(polarity = polarity(text)$all$polarity) %>% 
  filter(polarity < 0) %>% 
  pull(text) %>% 
  paste(collapse = " ")

# View the joined string
substr(neg_terms, 1, 100)


## ------------------------------------------------------------------------
# Concatenate the two strings into a vector with 2 elements
all_terms <- c(pos_terms, neg_terms)

# Convert the vector into a Corpus
corpus_all_terms <- VCorpus(VectorSource(all_terms))

# Convert the Corpus into a TermDocumentMatrix
tdm_all_terms <- TermDocumentMatrix(
  corpus_all_terms,
  control = list(
    weighting = weightTf,
    removePunctuation = TRUE
  )
)

# Convert the TDM into an R matrix object
matrix_all_terms <- as.matrix(tdm_all_terms)
colnames(matrix_all_terms) <- c("Positive", "Negative")

# View the TDM Matrix
tail(matrix_all_terms)


## ------------------------------------------------------------------------
# Plot a Comparison Cloud with the tidied TDM
comparison.cloud(matrix_all_terms, colors = c("green", "red"))


## ------------------------------------------------------------------------
commonality.cloud(matrix_all_terms, colors = "steelblue1")


## ------------------------------------------------------------------------
# Create a data.frame containing 25 of the most common terms to compare
top15_terms <-
  matrix_all_terms %>% 
  as_tibble(rownames = "word") %>% 
  filter_all(all_vars(. > 0)) %>% 
  mutate(difference = Positive - Negative) %>% 
  top_n(15, wt = difference) %>% 
  arrange(desc(difference))

# Examine the top 25 terms
head(top15_terms)


## ------------------------------------------------------------------------
# Create a Pyramid Plot to visualize the differences
library(plotrix)

pyramid.plot(
  top15_terms$Positive,
  top15_terms$Negative,
  labels = top15_terms$word,
  top.labels = c("Positive", "Word", "Negative"),
  main = "Words in Common",
  unit = NULL,
  gap = 10,
  space = 0.2
)



## ------------------------------------------------------------------------
# Create a Word Network plot with qdap'
word_associate(
  crude_df$text, 
  match.string = c("trump"), 
  stopwords = c("crude", stopwords("en")), 
  wordcloud = TRUE, 
  cloud.colors = c("gray85", "darkred"),
  nw.label.proportional = TRUE
  )

title(main = "Words Associated with Trump in #CrudeOil Tweets")


## ------------------------------------------------------------------------
# Create a Word Network plot with qdap'
word_associate(
  crude_df$text, 
  match.string = c("fed"), 
  stopwords = c("crude", stopwords("en")), 
  wordcloud = TRUE, 
  cloud.colors = c("gray85", "darkred"),
  nw.label.proportional = TRUE
  )

title(main = "Words Associated with Fed in #CrudeOil Tweets")


## ------------------------------------------------------------------------
# Export the analysis to an R Script
purl("crude-oil-sentiment-analysis.Rmd")
