// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MiniSocial {
    struct Post {
        string message;
        address author;
    }

    struct Room {
        string name;
        Post[] posts;
        mapping(address => bool) members;
    }

    struct Community {
        string name;
        mapping(string => Room) rooms; // mapping des salles par nom
        string[] roomNames; // liste des noms de salles
    }

    mapping(string => Community) private communities; // mapping des communautés par nom
    string[] private communityNames; // liste des noms de communautés

    // Événements pour la journalisation
    event CommunityAdded(string communityName);
    event RoomAdded(string communityName, string roomName);
    event PostPublished(string communityName, string roomName, string message, address author);
    event PostDeleted(string communityName, string roomName, uint index);
    event PostEdited(string communityName, string roomName, uint index, string newMessage);
    event UserJoinedRoom(string communityName, string roomName, address user);

    // Fonction pour ajouter une nouvelle communauté
    function addCommunity(string memory _communityName) public {
        require(bytes(_communityName).length > 0, "Community name cannot be empty.");
        require(bytes(communities[_communityName].name).length == 0, "Community already exists."); // Vérifie si la communauté existe déjà

        communities[_communityName].name = _communityName;
        communityNames.push(_communityName); // Ajoute à la liste des noms de communautés
        emit CommunityAdded(_communityName);
    }

    // Fonction pour ajouter une nouvelle salle à une communauté
    function addRoom(string memory _communityName, string memory _roomName) public {
        require(bytes(_communityName).length > 0, "Community name cannot be empty.");
        require(bytes(_roomName).length > 0, "Room name cannot be empty.");
        require(bytes(communities[_communityName].name).length > 0, "Community does not exist."); // Vérifie si la communauté existe
        require(bytes(communities[_communityName].rooms[_roomName].name).length == 0, "Room already exists."); // Vérifie si la salle existe déjà

        communities[_communityName].rooms[_roomName].name = _roomName; // Directly set the name of the new room
        communities[_communityName].roomNames.push(_roomName); // Ajoute à la liste des noms de salles
        emit RoomAdded(_communityName, _roomName);
    }

    // Fonction pour rejoindre une salle
    function joinRoom(string memory _communityName, string memory _roomName) public {
        require(bytes(communities[_communityName].name).length > 0, "Community does not exist.");
        require(bytes(communities[_communityName].rooms[_roomName].name).length > 0, "Room does not exist.");

        communities[_communityName].rooms[_roomName].members[msg.sender] = true; // Marque l'utilisateur comme membre
        emit UserJoinedRoom(_communityName, _roomName, msg.sender);
    }

    // Fonction pour publier un message dans une salle
    function publishPost(string memory _communityName, string memory _roomName, string memory _message) public {
        require(bytes(communities[_communityName].name).length > 0, "Community does not exist.");
        require(bytes(communities[_communityName].rooms[_roomName].name).length > 0, "Room does not exist.");
        require(communities[_communityName].rooms[_roomName].members[msg.sender], "You must join the room first."); // Vérifie si l'utilisateur est membre

        Post memory newPost = Post({
            message: _message,
            author: msg.sender
        });
        communities[_communityName].rooms[_roomName].posts.push(newPost); // Ajoute le message au tableau de posts
        emit PostPublished(_communityName, _roomName, _message, msg.sender);
    }

    // Fonction pour récupérer tous les messages d'une salle
    function getRoomPosts(string memory _communityName, string memory _roomName) public view returns (Post[] memory) {
        require(bytes(communities[_communityName].name).length > 0, "Community does not exist.");
        require(bytes(communities[_communityName].rooms[_roomName].name).length > 0, "Room does not exist.");

        return communities[_communityName].rooms[_roomName].posts; // Retourne tous les posts
    }

    // Fonction pour récupérer un message spécifique par index dans une salle
    function getPost(string memory _communityName, string memory _roomName, uint index) public view returns (string memory, address) {
        require(bytes(communities[_communityName].name).length > 0, "Community does not exist.");
        require(bytes(communities[_communityName].rooms[_roomName].name).length > 0, "Room does not exist.");
        require(index < communities[_communityName].rooms[_roomName].posts.length, "Index out of bounds."); // Vérifie l'index

        Post memory post = communities[_communityName].rooms[_roomName].posts[index];
        return (post.message, post.author);
    }

    // Fonction pour récupérer le nombre total de messages dans une salle
    function getTotalRoomPosts(string memory _communityName, string memory _roomName) public view returns (uint) {
        require(bytes(communities[_communityName].name).length > 0, "Community does not exist.");
        require(bytes(communities[_communityName].rooms[_roomName].name).length > 0, "Room does not exist.");

        return communities[_communityName].rooms[_roomName].posts.length; // Retourne le nombre de posts
    }

    // Fonction pour récupérer la liste des communautés
    function getCommunityNames() public view returns (string[] memory) {
        return communityNames; // Retourne la liste des noms de communautés
    }

    // Fonction pour récupérer la liste des salles dans une communauté
    function getRoomNames(string memory _communityName) public view returns (string[] memory) {
        require(bytes(communities[_communityName].name).length > 0, "Community does not exist.");
        return communities[_communityName].roomNames; // Retourne la liste des noms de salles
    }

    // Fonction pour supprimer un message spécifique dans une salle
    function deletePost(string memory _communityName, string memory _roomName, uint index) public {
        require(bytes(communities[_communityName].name).length > 0, "Community does not exist.");
        require(bytes(communities[_communityName].rooms[_roomName].name).length > 0, "Room does not exist.");
        require(index < communities[_communityName].rooms[_roomName].posts.length, "Index out of bounds.");
        require(communities[_communityName].rooms[_roomName].posts[index].author == msg.sender, "Only the author can delete this post."); // Vérifie que seul l'auteur peut supprimer le post

        // Supprime le post en déplaçant le dernier post à l'index supprimé
        communities[_communityName].rooms[_roomName].posts[index] = communities[_communityName].rooms[_roomName].posts[communities[_communityName].rooms[_roomName].posts.length - 1];
        communities[_communityName].rooms[_roomName].posts.pop(); // Supprime le dernier post
        emit PostDeleted(_communityName, _roomName, index);
    }

    // Fonction pour modifier un message spécifique dans une salle
    function editPost(string memory _communityName, string memory _roomName, uint index, string memory _newMessage) public {
        require(bytes(communities[_communityName].name).length > 0, "Community does not exist.");
        require(bytes(communities[_communityName].rooms[_roomName].name).length > 0, "Room does not exist.");
        require(index < communities[_communityName].rooms[_roomName].posts.length, "Index out of bounds.");
        require(communities[_communityName].rooms[_roomName].posts[index].author == msg.sender, "Only the author can edit this post."); // Vérifie que seul l'auteur peut éditer le post

        communities[_communityName].rooms[_roomName].posts[index].message = _newMessage; // Met à jour le message
        emit PostEdited(_communityName, _roomName, index, _newMessage);
    }
}
