// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.7;

contract Session {
    string public username;
    uint256 public login_datetime = 0;
    uint256 public logout_datetime = 0;

    constructor(string memory _username, uint256 login) {
        username = _username;
        login_datetime = login;
    }

    function logoutSession(uint256 logout) public {
        logout_datetime = logout;
    }
}

contract Appointment {
    string username;
    uint256 appointment_datetime;
    bool completed = false;
    string prescription = "None";

    constructor(string memory _username, uint256 _appointment_datetime) {
        username = _username;
        appointment_datetime = _appointment_datetime;
    }

    function changeAppointmentDate(uint256 new_appointment_datetime) public {
        appointment_datetime = new_appointment_datetime;
    }

    function changePrescription(string memory _prescription) public {
        prescription = _prescription;
    }

    function completeAppointment() public {
        completed = true;
    }
}

contract Users {
    event loginEvent(address value);
    event logoutEvent(string value);

    struct UserData {
        string username;
        bytes32 password;
        string sex;
        int256 height;
        int256 weight;
        string role;
    }

    mapping(string => UserData) private users;
    string[] users_lookup;

    mapping(string => address) private sessions;
    address[] sessions_lookup;

    mapping(address => string) private appointments;
    address[] appointments_lookup;

    function createUser(string memory _username, string memory _password)
        public
    {
        require(
            compareStrings(users[_username].username, ""),
            "Username already taken"
        );
        bytes32 hashed_password;
        hashed_password = keccak256(abi.encodePacked(_password));
        UserData memory newUser = UserData(
            _username,
            hashed_password,
            sex='',
            height=0;
            weight=0;
            role='user';
            );
        users[_username] = newUser;
        users_lookup.push(_username);
    }

    function createAppointment(
        string memory _username,
        uint256 _appointment_datetime
    ) public {
        Appointment appointment = new Appointment(
            _username,
            _appointment_datetime
        );
        appointments[address(appointment)] = _username;
        appointments_lookup.push(address(appointment));
    }

    function login(string memory _username, string memory _password) public {
        bytes32 hashed_password;
        hashed_password = keccak256(abi.encodePacked(_password));
        require(
            comparePassword(hashed_password, users[_username].password),
            "Incorrect password"
        );

        Session session = new Session(_username, block.timestamp);
        sessions[_username] = address(session);
        sessions_lookup.push(address(session));
        emit loginEvent(address(session));
    }

    function logout(string memory _username, address session)
        public
        returns (bool)
    {
        address[] storage sessionList = sessions[_username];
        for (uint256 i = 0; i < sessionList.length; i++) {
            if (sessionList[i] == session) {
                Session(sessionList[i]).logoutSession(block.timestamp);
                sessionList[i] = sessionList[sessionList.length - 1];
                sessionList.pop();
                emit LogoutEvent("logout successful");
                return true;
            }
        }

        emit LogoutEvent("logout failed");
        return false;
    }

    function giveRole(string memory _username, string memory _role) public {
        for (uint256 i=0; i < users_lookup; i++) {
            if (compareStrings(users_lookup[i], username)) {
                users[users_lookup[i]].role = _role;
            }
        }
    }

    function getUser(string memory _username)
        external
        view
        returns (UserData memory)
    {
        return users[_username];
    }

    function getUserAppointments(string memory _username)
        public
        view
        returns (address[] memory)
    {
        uint256 appointment_count = 0;
        for (uint256 i = 0; i < appointments_lookup.length; i++) {
            if (
                compareStrings(_username, appointments[appointments_lookup[i]])
            ) {
                appointment_count++;
            }
        }

        uint256 j = 0;
        address[] memory user_appointments = new address[](appointment_count);
        for (uint256 i = 0; i < appointments_lookup.length; i++) {
            if (
                compareStrings(_username, appointments[appointments_lookup[i]])
            ) {
                user_appointments[j] = appointments_lookup[i];
                j++;
            }
        }
        return user_appointments;
    }

    function getAllUsers() public view returns (UserData[] memory) {
        UserData[] memory allUsers = new UserData[](users_lookup.length);
        for (uint256 i = 0; i < users_lookup.length; i++) {
            allUsers[i] = users[users_lookup[i]];
        }
        return allUsers;
    }

    function getAllAppointments() public view returns (address[] memory) {
        return appointments_lookup;
    }

    function comparePassword(bytes32 a, bytes32 b) public pure returns (bool) {
        return a == b;
    }

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked(a)) ==
            keccak256(abi.encodePacked(b)));
    }
}
