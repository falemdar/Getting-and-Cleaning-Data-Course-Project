# The data files, maintaining their hierarchical folder structure, are placed 
# in the same directory as this script.


# Read and merge datasets with proper column names (step 1) ---------------

# List the files in the test and train folders that are to be read
# and place them in a data frame for easy access

test <- list.files("./test", ".txt", full.names = T)
train <- list.files("./train", ".txt", full.names = T)
files_df <- data.frame(test, train, stringsAsFactors = F)

m <- regexpr("([^//]+)\\.txt$", files_df$test)
var_names <- tolower(sub("_(test|train).txt", "", 
                         regmatches(files_df$test, m)))
row.names(files_df) <- var_names
# Sort rows to become columns in the desired order when the data is read
files_df <- files_df[c("subject", "y", "x"), ]

# Read data from test and train sets and merge them into one set, 
# along with activities and subject data

for (i in seq_along(files_df$test)) {
    d_test <- read.table(files_df[i, "test"])
    d_train <- read.table(files_df[i, "train"])
    d <- rbind(d_test, d_train)
    if (i == 1) {
        dataset <- d
    } else {
        dataset <- cbind(dataset, d)
    }
}

# Read features and activity labels to employ descriptive names
features <- read.delim("features.txt", sep = " ", header = F,
                       col.names = c("no", "feature"),
                       colClasses = c("NULL", "character"))

activity_labels <- read.delim("activity_labels.txt", sep = " ", 
                              header = F, col.names = c("no", "activity"))

# Character vector instead of data frame easier to place as column names
features <- as.vector(features[, 1])

# (Step 4) Rename the columns of the dataset with descriptive variable names
# This is the "step 4" in the assignment, but doing it now helps with filtering
# the mean() and std() measurements in step 2
names(dataset) <- c("subject", "activity", features)


# Extract mean and stdev variables only (step 2) --------------------------

library(dplyr)

# dataset <- dataset %>% select(subject, activity, matches("(mean|std)\\(\\)"))
# This produces error because there are multiple columns with the same name.

length(colnames(dataset)) - length(unique(colnames(dataset)))

# Let's find out and remove these duplicate columns first
count_colnames <- sort(table(colnames(dataset)))
count_colnames[count_colnames > 1]

# It is the ...bandsEnergy()... columns that we don't need, so remove them
keep_col <- names(dataset[, !grepl("bandsEnergy", names(dataset))])
dataset <- subset(dataset, select = keep_col)

# Now, eliminate measurements that are not mean() or std()
dataset <- dataset %>% select(subject, activity, matches("(mean|std)\\(\\)"))



# Use descriptive activity names (Step 3) ---------------------------------

# We had imported the activity labels into the activity_labels variable in
# step 1. But activities are in all caps, let's change them into lowercase
activity_labels$activity <- tolower(activity_labels$activity)

# Make the activity variable into a factor with level labels corresponding to
# the numbers, from activity_labels
dataset$activity <- factor(dataset$activity, labels = activity_labels$activity)

## Step 4 already covered in step 1, proceed to step 5

# Create a new summary dataset --------------------------------------------

# Firstly, let's make the subject variable into a factor as well
dataset$subject <- factor(dataset$subject, 1:30)

# Group the data by subject and activity and list the averages of the
# measurements per group
summary <- dataset %>% group_by(subject, activity) %>%
    summarize_all(funs(avg = mean))

# Save the tidy dataset into a text file
write.table(summary, file = "tidy_data.txt", row.names = F)

# Export the variables into a text file, forming a base for the code book
variables <- data.frame(names(summary))
write.table(variables, file = "variables.txt", row.names = F, 
            col.names = F, quote = F)
