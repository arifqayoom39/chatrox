import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:provider/provider.dart';
import 'package:chat/controllers/local_saved_data.dart';
import 'package:chat/main.dart';
import 'package:chat/models/chat_data_model.dart';
import 'package:chat/models/group_message_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/status_model.dart';
import 'package:chat/models/user_data.dart';
import 'package:chat/providers/chat_provider.dart';
import 'package:chat/providers/group_message_provider.dart';
import 'package:chat/providers/user_data_provider.dart';
import 'package:http/http.dart' as http;

Client client = Client()
  .setEndpoint('https://cloud.appwrite.io/v1')
  .setProject('example_project_id')
  .setSelfSigned(
    status: true); // For self signed certificates, only use for development

const String db = "example_db_id";
const String userCollection = "example_user_collection_id";
const String chatCollection = "example_chat_collection_id";
const String groupCollection = "example_group_collection_id";
const String groupMsgCollection = "example_group_msg_collection_id";
const String storageBucket = "example_storage_bucket_id";
const String statusCollection = "example_status_collection_id"; // Add this with other collection constants

Account account = Account(client);
final Databases databases = Databases(client);
final Storage storage = Storage(client);
final Realtime realtime = Realtime(client);

RealtimeSubscription? subscription;
RealtimeSubscription? groupMsgSubscription;
// to subscribe to realtime changes
subscribeToRealtime({required String userId}) {
  subscription = realtime.subscribe([
    "databases.$db.collections.$chatCollection.documents",
    "databases.$db.collections.$userCollection.documents"
  ]);

  print("subscribing to realtime");

  subscription!.stream.listen((data) {
    print("some event happend");
    // print(data.events);
    // print(data.payload);
    final firstItem = data.events[0].split(".");
    final eventType = firstItem[firstItem.length - 1];
    print("event type is $eventType");
    if (eventType == "create") {
      Provider.of<ChatProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadChats(userId);
    } else if (eventType == "update") {
      Provider.of<ChatProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadChats(userId);
    } else if (eventType == "delete") {
      Provider.of<ChatProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadChats(userId);
    }
  });
}

// to subscribe to realtime changes
subscribeToRealtimeGroupMsg({required String userId}) {
  subscription = realtime.subscribe([
    "databases.$db.collections.$groupCollection.documents",
    "databases.$db.collections.$groupMsgCollection.documents"
  ]);

  print("subscribing to realtime");

  subscription!.stream.listen((data) {
    print("some event happend");
    // print(data.events);
    // print(data.payload);
    final firstItem = data.events[0].split(".");
    final eventType = firstItem[firstItem.length - 1];
    print("event type is $eventType");
    if (eventType == "create") {
      Provider.of<GroupMessageProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadAllGroupRequiredData(userId);
    } else if (eventType == "update") {
      Provider.of<GroupMessageProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadAllGroupRequiredData(userId);
    } else if (eventType == "delete") {
      Provider.of<GroupMessageProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadAllGroupRequiredData(userId);
    }
  });
}

// save phone number to database (while creating a new account)
Future<bool> savePhoneToDb(
    {required String phoneno, required String userId}) async {
  try {
    final response = await databases.createDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {"phone_no": phoneno, "userId": userId});

    print(response);
    return true;
  } on AppwriteException catch (e) {
    print("Cannot save to user database :$e");
    return false;
  }
}

// check whether phone number exist in DB or not
Future<String> checkPhoneNumber({required String phoneno}) async {
  try {
    final DocumentList matchUser = await databases.listDocuments(
        databaseId: db,
        collectionId: userCollection,
        queries: [Query.equal("phone_no", phoneno)]);

    if (matchUser.total > 0) {
      final Document user = matchUser.documents[0];

      if (user.data["phone_no"] != null || user.data["phone_no"] != "") {
        return user.data["userId"];
      } else {
        print("no user exist on db");
        return "user_not_exist";
      }
    } else {
      print("no user exist on db");
      return "user_not_exist";
    }
  } on AppwriteException catch (e) {
    print("error on reading database $e");
    return "user_not_exist";
  }
}

// create a phone session , send otp to the phone number
Future<String> createPhoneSession({required String phone}) async {
  try {
    final userId = await checkPhoneNumber(phoneno: phone);
    if (userId == "user_not_exist") {
      // creating a new account
      final Token data =
          await account.createPhoneToken(userId: ID.unique(), phone: phone);

      // save the new user to user collection
      savePhoneToDb(phoneno: phone, userId: data.userId);
      return data.userId;
    }

    // if user is an existing user
    else {
      // create phone token for existing user
      final Token data =
          await account.createPhoneToken(userId: userId, phone: phone);
      return data.userId;
    }
  } catch (e) {
    print("error on create phone session :$e");
    return "login_error";
  }
}

// login with otp
Future<bool> loginWithOtp({required String otp, required String userId}) async {
  try {
    final Session session =
        await account.updatePhoneSession(userId: userId, secret: otp);
    print(session.userId);
    return true;
  } catch (e) {
    print("error on login with otp :$e");
    return false;
  }
}

// to check whether the session exist or not
Future<bool> checkSessions() async {
  try {
    final Session session = await account.getSession(sessionId: "current");
    print("session exist ${session.$id}");
    return true;
  } catch (e) {
    print("session does not exist please login");
    return false;
  }
}

// to logout the user and delete session
Future logoutUser() async {
  await account.deleteSession(sessionId: "current");
}

// load user data
Future<UserData?> getUserDetails({required String userId}) async {
  try {
    final response = await databases.getDocument(
        databaseId: db, collectionId: userCollection, documentId: userId);
    print("getting user data ");
    print(response.data);
    Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
        .setUserName(response.data["name"] ?? "");
    Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
        .setProfilePic(response.data["profile_pic"] ?? "");
    return UserData.toMap(response.data);
  } catch (e) {
    print("error in getting user data :$e");
    return null;
  }
}

// Check if user document exists in database
Future<bool> userDocumentExists({required String userId}) async {
  try {
    await databases.getDocument(
      databaseId: db, 
      collectionId: userCollection, 
      documentId: userId
    );
    return true;
  } catch (e) {
    if (e is AppwriteException && e.code == 404) {
      print("User document not found: document_not_found");
    } else {
      print("Error checking document existence: $e");
    }
    return false;
  }
}

// Create user document if it doesn't exist
Future<bool> createUserDocumentIfNotExists({
  required String userId,
  String? email,
  String? name,
  String? phoneNo,
  String? profilePic,
}) async {
  try {
    bool exists = await userDocumentExists(userId: userId);
    
    if (!exists) {
      await databases.createDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {
          "email": email ?? "",
          "userId": userId,
          "name": name ?? "",
          "phone_no": phoneNo ?? "",
          "profile_pic": profilePic ?? "",
          "isOnline": false,
        }
      );
      print("Created new user document for $userId");
    }
    return true;
  } catch (e) {
    print("Error creating user document: $e");
    return false;
  }
}

// to update the user Data
Future<bool> updateUserDetails(
  String pic, {
  required String userId,
  required String name,
  String? phoneNumber,
}) async {
  try {
    // First check if user document exists
    bool exists = await userDocumentExists(userId: userId);
    
    Map<String, dynamic> data = {
      "name": name, 
      "profile_pic": pic
    };
    
    // Add phone number to update if provided
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      data["phone_no"] = phoneNumber;
    }
    
    if (!exists) {
      // Get user account info
      try {
        final user = await account.get();
        
        // Create the document
        await createUserDocumentIfNotExists(
          userId: userId,
          email: user.email,
          name: name,
          phoneNo: phoneNumber,
          profilePic: pic
        );
        
        Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
          .setUserName(name);
        Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
          .setProfilePic(pic);
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
            .setUserPhone(phoneNumber);
        }
          
        return true;
      } catch (e) {
        print("Error creating user document during update: $e");
        return false;
      }
    }
    
    // Update existing document
    final updatedDoc = await databases.updateDocument(
      databaseId: db,
      collectionId: userCollection,
      documentId: userId,
      data: data
    );

    Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
        .setUserName(name);
    Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
        .setProfilePic(pic);
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
        .setUserPhone(phoneNumber);
    }
    
    print("User details updated successfully");
    return true;
  } on AppwriteException catch (e) {
    print("Cannot save to db: $e");
    
    // If document not found, try to create it
    if (e.code == 404) {
      return await createUserDocumentIfNotExists(
        userId: userId,
        name: name,
        phoneNo: phoneNumber,
        profilePic: pic
      );
    }
    return false;
  }
}

// upload and save image to storage bucket (create new image)
Future<String?> saveImageToBucket({required InputFile image}) async {
  try {
    final response = await storage.createFile(
        bucketId: storageBucket, fileId: ID.unique(), file: image);
    print("the response after save to bucket $response");
    return response.$id;
  } catch (e) {
    print("error on saving image to bucket :$e");
    return null;
  }
}

// update an image in bucket : first delete then create new
Future<String?> updateImageOnBucket(
    {required String oldImageId, required InputFile image}) async {
  try {
    // to delete the old image
    deleteImagefromBucket(oldImageId: oldImageId);

    // create a new image
    final newImage = saveImageToBucket(image: image);

    return newImage;
  } catch (e) {
    print("cannot update / delete image :$e");
    return null;
  }
}

// to only delete the image from the storage bucket

Future<bool> deleteImagefromBucket({required String oldImageId}) async {
  try {
    // to delete the old image
    await storage.deleteFile(bucketId: storageBucket, fileId: oldImageId);

    return true;
  } catch (e) {
    print("cannot update / delete image :$e");
    return false;
  }
}

// Audio handling functions
Future<String?> saveAudioToBucket({required InputFile audio}) async {
  try {
    final response = await storage.createFile(
        bucketId: storageBucket, fileId: ID.unique(), file: audio);
    print("audio saved to bucket successfully");
    return response.$id;
  } catch (e) {
    print("error on saving audio to bucket: $e");
    return null;
  }
}

Future<bool> deleteAudiofromBucket({required String oldAudioId}) async {
  try {
    await storage.deleteFile(bucketId: storageBucket, fileId: oldAudioId);
    print("audio deleted from bucket successfully");
    return true;
  } catch (e) {
    print("cannot delete audio: $e");
    return false;
  }
}

// Video handling functions
Future<String?> saveVideoToBucket({required InputFile video}) async {
  try {
    final response = await storage.createFile(
        bucketId: storageBucket, fileId: ID.unique(), file: video);
    print("video saved to bucket successfully");
    return response.$id;
  } catch (e) {
    print("error on saving video to bucket: $e");
    return null;
  }
}

Future<bool> deleteVideofromBucket({required String oldVideoId}) async {
  try {
    await storage.deleteFile(bucketId: storageBucket, fileId: oldVideoId);
    print("video deleted from bucket successfully");
    return true;
  } catch (e) {
    print("cannot delete video: $e");
    return false;
  }
}

// to search all the users from the database
Future<DocumentList?> searchUsers(
    {required String searchItem, required String userId}) async {
  try {
    final DocumentList users = await databases.listDocuments(
        databaseId: db,
        collectionId: userCollection,
        queries: [
          Query.search("phone_no", searchItem),
          Query.notEqual("userId", userId)
        ]);

    print("total match users ${users.total}");
    return users;
  } catch (e) {
    print("error on search users :$e");
    return null;
  }
}

// create a new chat and save to database
Future<bool> createNewChat({
  required String message,
  required String senderId,
  required String receiverId,
  required bool isImage,
  required bool isGroupInvite,
  bool? isAudio,
  bool? isVideo,
  String? replyMessage,
  String? replySender,
  String? replyMessageId,
  String? reaction,
  Map<String, dynamic>? userData,
}) async {
  try {
    final msg = await databases.createDocument(
        databaseId: db,
        collectionId: chatCollection,
        documentId: ID.unique(),
        data: {
          "message": message,
          "senderId": senderId,
          "receiverId": receiverId,
          "timestamp": DateTime.now().toIso8601String(),
          "isSeenbyReceiver": false,
          "isImage": isImage,
          "userData": [senderId, receiverId],
          "isGroupInvite": isGroupInvite,
          "isAudio": isAudio ?? false,
          "isVideo": isVideo ?? false,
          "replyMessage": replyMessage,
          "replySender": replySender,
          "replyMessageId": replyMessageId,
          "reaction": reaction,
        });

    print("message sent with all attributes");
    return true;
  } catch (e) {
    print("failed to send message: $e");
    return false;
  }
}

// to delete the chat from database chat collection
Future deleteCurrentUserChat({required String chatId}) async {
  try {
    await databases.deleteDocument(
        databaseId: db, collectionId: chatCollection, documentId: chatId);
  } catch (e) {
    print("error on deleting chat message : $e");
  }
}

// edit our chat message and update to database
Future<bool> editChat({
  required String chatId,
  String? message,
  String? reaction,
}) async {
  try {
    Map<String, dynamic> data = {};
    
    if (message != null) {
      data["message"] = message;
    }
    
    if (reaction != null) {
      data["reaction"] = reaction;
    }
    
    if (data.isNotEmpty) {
      await databases.updateDocument(
          databaseId: db,
          collectionId: chatCollection,
          documentId: chatId,
          data: data);
      print("message updated successfully with new attributes");
      return true;
    } else {
      print("No data to update");
      return false;
    }
  } catch (e) {
    print("error on editing message: $e");
    return false;
  }
}

// to list all the chats belonging to the current user
Future<Map<String, List<ChatDataModel>>?> currentUserChats(
    String userId) async {
  try {
    var results = await databases
        .listDocuments(databaseId: db, collectionId: chatCollection, queries: [
      Query.or(
          [Query.equal("senderId", userId), Query.equal("receiverId", userId)]),
      Query.orderDesc("timestamp"),
      Query.limit(2000)
    ]);

    final DocumentList chatDocuments = results;

    print(
        "chat documents ${chatDocuments.total} and documents ${chatDocuments.documents.length}");
    Map<String, List<ChatDataModel>> chats = {};

    if (chatDocuments.documents.isNotEmpty) {
      for (var i = 0; i < chatDocuments.documents.length; i++) {
        var doc = chatDocuments.documents[i];
        String sender = doc.data["senderId"];
        String receiver = doc.data["receiverId"];

        MessageModel message = MessageModel.fromMap(doc.data);

        List<UserData> users = [];
        for (var user in doc.data["userData"]) {
          users.add(UserData.toMap(user));
        }

        String key = (sender == userId) ? receiver : sender;

        if (chats[key] == null) {
          chats[key] = [];
        }
        chats[key]!.add(ChatDataModel(message: message, users: users));
      }
    }

    return chats;
  } catch (e) {
    print("error in reading current user chats :$e");
    return null;
  }
}

// to update isSeen message status
Future updateIsSeen({required List<String> chatsIds}) async {
  try {
    for (var chatid in chatsIds) {
      // First get the current document to access its isGroupInvite value
      final doc = await databases.getDocument(
        databaseId: db, 
        collectionId: chatCollection, 
        documentId: chatid
      );
      
      // Now update with all required fields included
      await databases.updateDocument(
          databaseId: db,
          collectionId: chatCollection,
          documentId: chatid,
          data: {
            "isSeenbyReceiver": true,
            "isGroupInvite": doc.data["isGroupInvite"] ?? false,
          });
      print("update is seen");
    }
  } catch (e) {
    print("error in update isseen :$e");
  }
}

// to update the online status
Future updateOnlineStatus(
    {required bool status, required String userId}) async {
  try {
    await databases.updateDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {"isOnline": status});
    print("updated user online status $status ");
  } catch (e) {
    print("unable to update online status : $e");
  }
}

// to save users device token to user collection
Future saveUserDeviceToken(String token, String userId) async {
  try {
    await databases.updateDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {"device_token": token});
    print("device token saved to db");

    return true;
  } catch (e) {
    print("cannot save device token :$e");
    return false;
  }
}

// to send notification to other user
Future sendNotificationtoOtherUser({
  required String notificationTitle,
  required String notificationBody,
  required String deviceToken,
}) async {
  try {
    print("sending notification");
    final Map<String, dynamic> body = {
      "deviceToken": deviceToken,
      "message": {"title": notificationTitle, "body": notificationBody},
    };

    final response = await http.post(
        Uri.parse("https://682ad5459a25e7cd3947.fra.appwrite.run/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body));

    if (response.statusCode == 200) {
      print("notification send to other user");
    }
  } catch (e) {
    print("notification cannot be sent");
  }
}

// Group Functions
// create a new group
Future<bool> createNewGroup(
    {required String currentUser,
    required String groupName,
    required String groupDesc,
    bool? isOpen,
    bool allowAllToSendMessages = true, // New parameter
    required String image}) async {
  try {
    await databases.createDocument(
        databaseId: db,
        collectionId: groupCollection,
        documentId: ID.unique(),
        data: {
          "admin": currentUser,
          "group_name": groupName,
          "group_desc": groupDesc,
          "image": image,
          "isPublic": isOpen,
          "members": [currentUser],
          "userData": [currentUser],
          "moderators": [], // Initialize empty moderators array
          "allowAllToSendMessages": allowAllToSendMessages, // Add permission setting
        });
    return true;
  } catch (e) {
    print("Failed to create new group $e");
    return false;
  }
}

Future<bool> updateExistingGroup(
    {required String groupId,
    required String groupName,
    required String groupDesc,
    bool? isOpen,
    bool? allowAllToSendMessages, // New parameter
    required String image}) async {
  try {
    Map<String, dynamic> data = {
      "group_name": groupName,
      "group_desc": groupDesc,
      "image": image,
      "isPublic": isOpen,
    };
    
    // Only include if provided
    if (allowAllToSendMessages != null) {
      data["allowAllToSendMessages"] = allowAllToSendMessages;
    }
    
    await databases.updateDocument(
        databaseId: db,
        collectionId: groupCollection,
        documentId: groupId,
        data: data);
    return true;
  } catch (e) {
    print("Failed to update the group $e");
    return false;
  }
}

// Add a dedicated function to update just the message permissions
Future<bool> updateGroupMessagePermission({
  required String groupId,
  required bool allowAllToSendMessages,
}) async {
  try {
    await databases.updateDocument(
      databaseId: db,
      collectionId: groupCollection,
      documentId: groupId,
      data: {
        "allowAllToSendMessages": allowAllToSendMessages,
      }
    );
    print("Group message permissions updated successfully");
    return true;
  } catch (e) {
    print("Failed to update group message permissions: $e");
    return false;
  }
}

// Function to check if a user can send messages in a group
Future<bool> canUserSendMessages({
  required String groupId,
  required String userId,
}) async {
  try {
    // Get the group document
    final doc = await databases.getDocument(
      databaseId: db,
      collectionId: groupCollection,
      documentId: groupId,
    );
    
    // If everyone can send messages
    if (doc.data["allowAllToSendMessages"] == true) {
      return true;
    }
    
    // Admin can always send messages
    if (doc.data["admin"] == userId) {
      return true;
    }
    
    // Check if user is a moderator
    List<dynamic> moderatorsDynamic = doc.data["moderators"] ?? [];
    List<String> moderators = moderatorsDynamic.map((item) => item.toString()).toList();
    
    return moderators.contains(userId);
  } catch (e) {
    print("Error checking message permissions: $e");
    return false; // Default to false on error
  }
}

// read all the groups current user is joined now.
Future<DocumentList?> readAllGroups({required String currentUserId}) async {
  try {
    var result = await databases.listDocuments(
        databaseId: db,
        collectionId: groupCollection,
        queries: [Query.equal("members", currentUserId), Query.limit(100)]);

    return result;
  } catch (e) {
    print("error on reading group $e");
    return null;
  }
}

// GROUP MESSAGES
// send a message to the group
Future<bool> sendGroupMessage({
  required String groupId,
  required String message,
  required String senderId,
  bool? isImage,
  bool? isAudio,
  bool? isVideo,
  String? replyMessage,
  String? replySender,
  String? replyMessageId,
  String? reaction,
}) async {
  try {
    await databases.createDocument(
        databaseId: db,
        collectionId: groupMsgCollection,
        documentId: ID.unique(),
        data: {
          "groupId": groupId,
          "message": message,
          "senderId": senderId,
          "timestamp": DateTime.now().toIso8601String(),
          "isImage": isImage ?? false,
          "isAudio": isAudio ?? false,
          "isVideo": isVideo ?? false,
          "replyMessage": replyMessage,
          "replySender": replySender,
          "replyMessageId": replyMessageId,
          "reaction": reaction,
          "userData": [senderId]
        });
    return true;
  } catch (e) {
    print("error on sending group message ");
    return false;
  }
}

// Add function to add a reaction to a group message
Future<bool> addReactionToGroupMessage({
  required String messageId,
  required String reaction,
}) async {
  try {
    await databases.updateDocument(
      databaseId: db,
      collectionId: groupMsgCollection,
      documentId: messageId,
      data: {
        "reaction": reaction,
      },
    );
    return true;
  } catch (e) {
    print("error adding reaction to group message: $e");
    return false;
  }
}

// update the group message
Future<bool> updateGroupMessage({required String messageId,required String newMessage})async{
  try{
    await databases.updateDocument(databaseId: db,
     collectionId: groupMsgCollection, documentId: messageId
     ,data:  {
      "message":newMessage
     });
     return true;
  }
  catch(e){
    print("error on updating group chat :$e");
    return false;
  }
}

// delete the specific group message
Future deleteGroupMessage({required String messageId})async{
  try{
    await databases.deleteDocument(databaseId: db, 
    collectionId: groupMsgCollection, documentId: messageId);
  }
  catch(e){
    print("error in deleting group message :$e");
  }
}

// reading all the group messages
Future<Map<String, List<GroupMessageModel>>?> readGroupMessages(
    {required List<String> groupIds}) async {
  try {
    var results = await databases
        .listDocuments(databaseId: db, collectionId: groupMsgCollection, queries: [
          Query.equal("groupId",groupIds),
      Query.orderDesc("timestamp"),
      Query.limit(2000)
    ]);

    final DocumentList groupChatDocuments = results;

 
    Map<String, List<GroupMessageModel>> chats = {};

    if (groupChatDocuments.documents.isNotEmpty) {
      for (var i = 0; i < groupChatDocuments.documents.length; i++) {
        var doc = groupChatDocuments.documents[i];
      
        GroupMessageModel message = GroupMessageModel.fromMap(doc.data);
         String groupId = doc.data["groupId"];

        String key =groupId;

        if (chats[key] == null) {
          chats[key] = [];
        }
        chats[key]!.add(message);
      }
    }

    print("loaded chats ${chats.length}");

    return chats;
  } catch (e) {
    print("error in reading group chat messages :$e");
    return null;
  }
}

// to add the user to the specific group
Future<bool> addUserToGroup({required String groupId,required String currentUser})async{
  try{
    //  read the group members first
    final result= await databases.getDocument(databaseId: db,
     collectionId: groupCollection, documentId: groupId, queries: [Query.select(["members"])]);

     List existingMembers= result.data["members"];

     if(!existingMembers.contains(currentUser)){
      existingMembers.add(currentUser);
     }

    //  update the document of the specific group
    await databases.updateDocument(databaseId: db, 
    collectionId: groupCollection, documentId: groupId,
    data: {
      "members":existingMembers,
      "userData":existingMembers
    });
    return true;
  }
  catch(e){
    print("error on joining group :$e");
    return false;
  }
}

// to exit the specific group
Future<bool>exitGroup({required String groupId, required String currentUser})async{
   try{
    //  read the group members first
    final result= await databases.getDocument(databaseId: db,
     collectionId: groupCollection, documentId: groupId, queries: [Query.select(["members"])]);

     List existingMembers= result.data["members"];

     if(existingMembers.contains(currentUser)){
      existingMembers.remove(currentUser);
     }

    //  update the document of the specific group
    await databases.updateDocument(databaseId: db, 
    collectionId: groupCollection, documentId: groupId,
    data: {
      "members":existingMembers,
      "userData":existingMembers
    });
    return true;
  }
  catch(e){
    print("error on leaving group :$e");
    return false;
  }
}

// calculate the no of last unreadMessages
  Future<int> calculateUnreadMessages(String groupId, List<GroupMessageModel> groupMessages) async {
  Map<String, String> lastSeenMessages = await LocalSavedData. getLastSeenMessages();
  String? lastSeenMessageId = lastSeenMessages[groupId];

  if (lastSeenMessageId == null) {
    return groupMessages.length; 
  }

  int unreadCount = groupMessages.indexWhere((message) => message.messageId == lastSeenMessageId);
  if (unreadCount == -1) {
    return groupMessages.length; 
  }

  return groupMessages.length - unreadCount - 1; 
}

// save last message seen in the group
 Future<void> updateLastMessageSeen(String groupId, String lastMessageSeenId) async {
  Map<String, String> lastSeenMessages = await LocalSavedData.getLastSeenMessages();
  print("last seen messages: $lastSeenMessages");
  lastSeenMessages[groupId] = lastMessageSeenId; 
  await LocalSavedData. saveLastSeenMessages(lastSeenMessages); 
}

// list all public groups
Future <List<Document>> getPublicGroups()async{
  try{
    final results = await databases.listDocuments(
        databaseId: db, collectionId: groupCollection, queries: [
          Query.equal("isPublic", true),
        ]
    );
    print("result got");
    print(results.documents.length);
    return results.documents;
    
  }catch(e){
    print("error in getting public groups $e");
    return [];
  }
}


// send notifications to multiple users at once
Future sendMultipleNotificationtoOtherUser({
  required String notificationTitle,
  required String notificationBody,
  required List<String> deviceToken,
}) async {
  try {
    print("sending notification");
    final Map<String, dynamic> body = {
      "deviceToken": deviceToken,
      "message": {"title": notificationTitle, "body": notificationBody},
    };

    final response = await http.post(
        Uri.parse("https://6639e5cdc5c67686b510.appwrite.global/many"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body));

    if (response.statusCode == 200) {
      print("notification send to other user");
    }
  } catch (e) {
    print("notification cannot be sent");
  }
}

// Contact Sync Functions
Future<List<Document>> syncContacts({
  required List<String> phoneNumbers,
  required String currentUserId,
}) async {
  try {
    // Query the database for the batch of phone numbers
    final DocumentList matchedUsers = await databases.listDocuments(
      databaseId: db,
      collectionId: userCollection,
      queries: [
        Query.equal("phone_no", phoneNumbers),
        Query.notEqual("userId", currentUserId),
      ],
    );
    
    print("Found ${matchedUsers.total} matches from this batch of contacts");
    return matchedUsers.documents;
  } catch (e) {
    print("Error syncing contacts: $e");
    return [];
  }
}

// Process contacts in batches of 30
Future<List<Document>> batchSyncContacts({
  required List<String> allPhoneNumbers,
  required String currentUserId,
}) async {
  List<Document> allSyncedContacts = [];
  
  // Process in batches of 30
  for (int i = 0; i < allPhoneNumbers.length; i += 30) {
    int end = (i + 30 < allPhoneNumbers.length) ? i + 30 : allPhoneNumbers.length;
    List<String> batch = allPhoneNumbers.sublist(i, end);
    
    List<Document> batchResults = await syncContacts(
      phoneNumbers: batch,
      currentUserId: currentUserId,
    );
    
    allSyncedContacts.addAll(batchResults);
    print("Processed batch ${(i ~/ 30) + 1}, total synced contacts: ${allSyncedContacts.length}");
  }
  
  return allSyncedContacts;
}

// STATUS RELATED FUNCTIONS

// Create a new status
Future<bool> createStatus({
  required String userId,
  required String imageUrl,
  String? caption,
}) async {
  try {
    final statusId = ID.unique();
    await databases.createDocument(
      databaseId: db,
      collectionId: statusCollection,
      documentId: statusId,
      data: {
        "statusId": statusId,
        "userId": userId,
        "imageUrl": imageUrl,
        "caption": caption,
        "timestamp": DateTime.now().toIso8601String(),
        "viewedBy": [],
        "userData": [userId],
      },
    );
    print("Status created successfully");
    return true;
  } catch (e) {
    print("Error creating status: $e");
    return false;
  }
}

// Get all statuses from contacts (within last 24 hours)
Future<List<StatusModel>> getContactStatuses({
  required List<String> contactIds,
  required String currentUserId,
}) async {
  try {
    // Get the timestamp for 24 hours ago
    DateTime twentyFourHoursAgo = DateTime.now().subtract(Duration(hours: 24));
    String twentyFourHoursAgoStr = twentyFourHoursAgo.toIso8601String();

    // Add current user to see their own status too
    if (!contactIds.contains(currentUserId)) {
      contactIds.add(currentUserId);
    }

    // Query for statuses
    final results = await databases.listDocuments(
      databaseId: db,
      collectionId: statusCollection,
      queries: [
        Query.equal("userId", contactIds),
        Query.greaterThan("timestamp", twentyFourHoursAgoStr),
        Query.orderDesc("timestamp"),
        Query.limit(100),
      ],
    );

    List<StatusModel> statuses = [];
    
    // Convert documents to StatusModel objects
    for (var doc in results.documents) {
      StatusModel status = StatusModel.fromMap(doc.data);
      
      // Get user details for this status
      try {
        final userResponse = await databases.getDocument(
          databaseId: db, 
          collectionId: userCollection, 
          documentId: status.userId
        );
        
        if (userResponse != null) {
          status.userData = UserData.toMap(userResponse.data);
        }
      } catch (e) {
        print("Error fetching user data for status: $e");
      }
      
      statuses.add(status);
    }

    return statuses;
  } catch (e) {
    print("Error getting contact statuses: $e");
    return [];
  }
}

// Get current user's own statuses (within last 24 hours)
Future<List<StatusModel>> getUserOwnStatuses({
  required String userId,
}) async {
  try {
    // Get the timestamp for 24 hours ago
    DateTime twentyFourHoursAgo = DateTime.now().subtract(Duration(hours: 24));
    String twentyFourHoursAgoStr = twentyFourHoursAgo.toIso8601String();

    // Query for statuses
    final results = await databases.listDocuments(
      databaseId: db,
      collectionId: statusCollection,
      queries: [
        Query.equal("userId", userId),
        Query.greaterThan("timestamp", twentyFourHoursAgoStr),
        Query.orderDesc("timestamp"),
        Query.limit(100),
      ],
    );

    List<StatusModel> statuses = [];
    
    // Convert documents to StatusModel objects and attach user data
    for (var doc in results.documents) {
      StatusModel status = StatusModel.fromMap(doc.data);
      
      // Get user details for this status
      try {
        final userResponse = await databases.getDocument(
          databaseId: db, 
          collectionId: userCollection, 
          documentId: userId
        );
        
        if (userResponse != null) {
          status.userData = UserData.toMap(userResponse.data);
        }
      } catch (e) {
        print("Error fetching user data for own status: $e");
      }
      
      statuses.add(status);
    }

    return statuses;
  } catch (e) {
    print("Error getting user statuses: $e");
    return [];
  }
}

// Mark a status as viewed by current user
Future<bool> markStatusAsViewed({
  required String statusId,
  required String userId,
}) async {
  try {
    // First get the current document to access its viewedBy array
    final doc = await databases.getDocument(
      databaseId: db,
      collectionId: statusCollection,
      documentId: statusId,
    );

    // Get the current viewedBy list
    List<dynamic> viewedByDynamic = doc.data["viewedBy"] ?? [];
    List<String> viewedBy = viewedByDynamic.map((item) => item.toString()).toList();

    // Add the user if not already in the list
    if (!viewedBy.contains(userId)) {
      viewedBy.add(userId);
      
      // Update the document
      await databases.updateDocument(
        databaseId: db,
        collectionId: statusCollection,
        documentId: statusId,
        data: {
          "viewedBy": viewedBy,
        },
      );
      
      // Also store locally
      await LocalSavedData.addViewedStatusId(statusId);
      
      print("Status marked as viewed by $userId");
    }

    return true;
  } catch (e) {
    print("Error marking status as viewed: $e");
    return false;
  }
}

// Delete a status
Future<bool> deleteStatus({
  required String statusId,
}) async {
  try {
    await databases.deleteDocument(
      databaseId: db,
      collectionId: statusCollection,
      documentId: statusId,
    );
    print("Status deleted successfully");
    return true;
  } catch (e) {
    print("Error deleting status: $e");
    return false;
  }
}

// Add user as moderator to a group
Future<bool> addModerator({
  required String groupId,
  required String userId,
}) async {
  try {
    // First get the current document to access its moderators list
    final doc = await databases.getDocument(
      databaseId: db,
      collectionId: groupCollection,
      documentId: groupId,
    );

    // Get existing moderators or initialize empty list
    List<dynamic> moderatorsDynamic = doc.data["moderators"] ?? [];
    List<String> moderators = moderatorsDynamic.map((item) => item.toString()).toList();

    // Add user if not already a moderator
    if (!moderators.contains(userId)) {
      moderators.add(userId);
      
      // Update the document
      await databases.updateDocument(
        databaseId: db,
        collectionId: groupCollection,
        documentId: groupId,
        data: {
          "moderators": moderators,
        },
      );
    }
    
    return true;
  } catch (e) {
    print("Error adding moderator: $e");
    return false;
  }
}

// Remove user from moderators
Future<bool> removeModerator({
  required String groupId,
  required String userId,
}) async {
  try {
    // First get the current document to access its moderators list
    final doc = await databases.getDocument(
      databaseId: db,
      collectionId: groupCollection,
      documentId: groupId,
    );

    // Get existing moderators or initialize empty list
    List<dynamic> moderatorsDynamic = doc.data["moderators"] ?? [];
    List<String> moderators = moderatorsDynamic.map((item) => item.toString()).toList();

    // Remove user if they are a moderator
    if (moderators.contains(userId)) {
      moderators.remove(userId);
      
      // Update the document
      await databases.updateDocument(
        databaseId: db,
        collectionId: groupCollection,
        documentId: groupId,
        data: {
          "moderators": moderators,
        },
      );
    }
    
    return true;
  } catch (e) {
    print("Error removing moderator: $e");
    return false;
  }
}

// Check if user is a moderator or admin of a group
Future<bool> isModeratorOrAdmin({
  required String groupId,
  required String userId,
}) async {
  try {
    final doc = await databases.getDocument(
      databaseId: db,
      collectionId: groupCollection,
      documentId: groupId,
    );

    // Check if user is admin
    if (doc.data["admin"] == userId) {
      return true;
    }

    // Get moderators list
    List<dynamic> moderatorsDynamic = doc.data["moderators"] ?? [];
    List<String> moderators = moderatorsDynamic.map((item) => item.toString()).toList();

    // Check if user is a moderator
    return moderators.contains(userId);
  } catch (e) {
    print("Error checking moderator/admin status: $e");
    return false;
  }
}

// Email authentication methods
Future<String> createEmailAccount({required String email, required String password, required String name}) async {
  try {
    // Create the account with Appwrite Auth
    final user = await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name
    );
    
    // Create a session for the new user
    await account.createEmailPasswordSession(email: email, password: password);
    
    // Create user document in database explicitly - don't just check if it exists
    try {
      await databases.createDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: user.$id,
        data: {
          "email": email, 
          "userId": user.$id,
          "name": name,
          "phone_no": "",
          "profile_pic": "",
          "isOnline": false,
        }
      );
      print("Created new user document for signup: ${user.$id}");
    } catch (docError) {
      print("Error creating initial user document: $docError");
      // Continue anyway as the auth account was created
    }
    
    print("Email account created successfully: ${user.$id}");
    return user.$id;
  } on AppwriteException catch (e) {
    print("Error creating email account: $e");
    if (e.code == 409) {
      return "email_exists";
    }
    return "signup_error";
  }
}

Future<bool> loginWithEmail({required String email, required String password}) async {
  try {
    final session = await account.createEmailPasswordSession(email: email, password: password);
    print("Email login successful: ${session.userId}");
    
    // Ensure user document exists
    await createUserDocumentIfNotExists(
      userId: session.userId,
      email: email
    );
    
    return true;
  } on AppwriteException catch (e) {
    print("Error logging in with email: $e");
    return false;
  }
}

Future<bool> saveEmailUserToDb({required String email, required String userId, String? name}) async {
  try {
    final response = await databases.createDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {
          "email": email, 
          "userId": userId,
          "name": name ?? "",
          "phone_no": "", // Initialize empty phone number that can be added later
        });

    print("Email user saved to database");
    return true;
  } on AppwriteException catch (e) {
    print("Cannot save email user to database: $e");
    return false;
  }
}

Future<bool> updateUserPhoneNumber({required String userId, required String phoneNumber}) async {
  try {
    await databases.updateDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {"phone_no": phoneNumber});
    
    print("Phone number updated for email user");
    return true;
  } on AppwriteException catch (e) {
    print("Error updating phone number: $e");
    return false;
  }
}

Future<bool> resetPassword({required String email}) async {
  try {
    await account.createRecovery(email: email, url: "fastchatapp://reset-password");
    print("Password reset email sent");
    return true;
  } on AppwriteException catch (e) {
    print("Error sending password reset: $e");
    return false;
  }
}

Future<String?> getUserAccount() async {
  try {
    final user = await account.get();
    return user.$id;
  } on AppwriteException catch (e) {
    print("Error getting user account: $e");
    return null;
  }
}

// Get user data by email
Future<UserData?> getUserDetailsByEmail({required String email}) async {
  try {
    final DocumentList matchUser = await databases.listDocuments(
        databaseId: db,
        collectionId: userCollection,
        queries: [Query.equal("email", email)]);

    if (matchUser.total > 0) {
      final Document user = matchUser.documents[0];
      return UserData.toMap(user.data);
    } else {
      print("No user exists with this email");
      return null;
    }
  } on AppwriteException catch (e) {
    print("Error finding user by email: $e");
    return null;
  }
}