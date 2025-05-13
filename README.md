# Splitzy - Group Expense Manager

Splitzy is a mobile app that helps users manage and split group expenses, making it easy for groups to track and settle shared costs. With features like group creation, expense splitting, and activity feeds, Splitzy simplifies group finance management.

## Features

- **User Registration**: Users can register with their UPI ID and validate their username.
- **Group Creation & Management**: Create groups and manage members (admin control).
- **Expense Splitting**: Add expenses and split them among group members.
- **Have to Pay & Have to Receive**: See amounts owed and amounts to be received for settlements.
- **Activity Feed**: View a feed of group actions and expenses.
- **Account Settings & Logout**: Manage account settings and log out when needed.
- **Firebase Firestore**: Used for the backend to store user data, expenses, and group information.
- **State Management**: `setState` is used for simple state management throughout the app.

## Technologies Used

- **Flutter**: Framework used for building the cross-platform mobile app.
- **Dart**: Programming language used for writing the app.
- **Firebase Firestore**: Cloud-based NoSQL database for storing user and group data.
- **setState**: Flutter's built-in method for managing state locally within the app.

## Installation

Follow these steps to get the Splitzy app up and running locally:

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/your-username/splitzy.git
   cd splitzy


2. **Install Dependencies**:
   Run the following command to install the required packages:
   ```bash
   flutter pub get

3. **Set up Firebase:**:
   Go to the Firebase Console and create a new project.
   Add your Android/iOS app to Firebase and download the google-services.json (for Android) or GoogleService-Info.plist (for iOS).
   Place the respective file in the android/app or ios/Runner directory of your Flutter project.

4. **Run the App**:
    ```bash
   flutter run
