// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ChainRateSystem
 * @dev 链评系统的主合约，处理用户认证、课程管理和评价功能
 */
contract ChainRateSystem {
    // 用户角色
    enum Role { TEACHER, STUDENT }
    
    // 用户结构
    struct User {
        address userAddress;
        string username;
        string passwordHash; // 实际项目中应在前端加密，这里仅用于演示
        Role role;
        bool isRegistered;
    }
    
    // 课程结构
    struct Course {
        uint256 id;
        string name;
        string description;
        address teacherAddress;
        uint256 creationTime;
        bool isActive;
    }
    
    // 学生加入课程记录
    struct Enrollment {
        address studentAddress;
        uint256 courseId;
        uint256 enrollmentTime;
    }
    
    // 评价结构
    struct Rating {
        uint256 id;
        uint256 courseId;
        address studentAddress;
        uint8 score; // 1-5分
        string comment;
        bool isAnonymous;
        uint256 timestamp;
    }
    
    // 存储用户信息
    mapping(address => User) public users;
    
    // 存储课程信息
    mapping(uint256 => Course) public courses;
    uint256 public courseCounter = 0;
    
    // 存储学生加入的课程
    mapping(address => uint256[]) public studentCourses;
    mapping(uint256 => address[]) public courseStudents;
    
    // 存储评价信息
    mapping(uint256 => Rating) public ratings;
    uint256 public ratingCounter = 0;
    
    // 课程评价映射
    mapping(uint256 => uint256[]) public courseRatings;
    
    // 事件
    event UserRegistered(address indexed userAddress, string username, Role role);
    event CourseCreated(uint256 indexed courseId, string name, address indexed teacherAddress);
    event StudentEnrolled(address indexed studentAddress, uint256 indexed courseId);
    event RatingSubmitted(uint256 indexed ratingId, uint256 indexed courseId, address indexed studentAddress, bool isAnonymous);
    
    // 修饰符：只有已注册用户可调用
    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "User is not registered");
        _;
    }
    
    // 修饰符：只有教师可调用
    modifier onlyTeacher() {
        require(users[msg.sender].isRegistered && users[msg.sender].role == Role.TEACHER, "User is not a teacher");
        _;
    }
    
    // 修饰符：只有学生可调用
    modifier onlyStudent() {
        require(users[msg.sender].isRegistered && users[msg.sender].role == Role.STUDENT, "User is not a student");
        _;
    }
    
    /**
     * @dev 注册新用户
     * @param _username 用户名
     * @param _passwordHash 密码哈希
     * @param _role 用户角色 (0: 教师, 1: 学生)
     */
    function registerUser(string memory _username, string memory _passwordHash, Role _role) public {
        require(!users[msg.sender].isRegistered, "User already registered");
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(bytes(_passwordHash).length > 0, "Password cannot be empty");
        
        users[msg.sender] = User({
            userAddress: msg.sender,
            username: _username,
            passwordHash: _passwordHash,
            role: _role,
            isRegistered: true
        });
        
        emit UserRegistered(msg.sender, _username, _role);
    }
    
    /**
     * @dev 验证用户登录（实际上应在前端完成，合约只需验证地址）
     * @param _passwordHash 密码哈希
     * @return 是否登录成功
     */
    function login(string memory _passwordHash) public view returns (bool) {
        return (users[msg.sender].isRegistered && 
                keccak256(abi.encodePacked(users[msg.sender].passwordHash)) == 
                keccak256(abi.encodePacked(_passwordHash)));
    }
    
    /**
     * @dev 教师创建新课程
     * @param _name 课程名称
     * @param _description 课程描述
     */
    function createCourse(string memory _name, string memory _description) public onlyTeacher {
        require(bytes(_name).length > 0, "Course name cannot be empty");
        
        uint256 courseId = courseCounter;
        courseCounter++;
        
        courses[courseId] = Course({
            id: courseId,
            name: _name,
            description: _description,
            teacherAddress: msg.sender,
            creationTime: block.timestamp,
            isActive: true
        });
        
        emit CourseCreated(courseId, _name, msg.sender);
    }
    
    /**
     * @dev 学生加入课程
     * @param _courseId 课程ID
     */
    function enrollInCourse(uint256 _courseId) public onlyStudent {
        require(courses[_courseId].isActive, "Course does not exist or is not active");
        
        // 检查学生是否已经加入该课程
        uint256[] memory enrolledCourses = studentCourses[msg.sender];
        for (uint256 i = 0; i < enrolledCourses.length; i++) {
            if (enrolledCourses[i] == _courseId) {
                revert("Student already enrolled in this course");
            }
        }
        
        // 将课程加入学生的课程列表
        studentCourses[msg.sender].push(_courseId);
        
        // 将学生加入课程的学生列表
        courseStudents[_courseId].push(msg.sender);
        
        emit StudentEnrolled(msg.sender, _courseId);
    }
    
    /**
     * @dev 学生对课程进行评价
     * @param _courseId 课程ID
     * @param _score 评分 (1-5)
     * @param _comment 评价内容
     * @param _isAnonymous 是否匿名
     */
    function rateCourse(uint256 _courseId, uint8 _score, string memory _comment, bool _isAnonymous) public onlyStudent {
        require(courses[_courseId].isActive, "Course does not exist or is not active");
        require(_score >= 1 && _score <= 5, "Score must be between 1 and 5");
        
        // 检查学生是否已加入该课程
        bool isEnrolled = false;
        uint256[] memory enrolledCourses = studentCourses[msg.sender];
        for (uint256 i = 0; i < enrolledCourses.length; i++) {
            if (enrolledCourses[i] == _courseId) {
                isEnrolled = true;
                break;
            }
        }
        require(isEnrolled, "Student is not enrolled in this course");
        
        uint256 ratingId = ratingCounter;
        ratingCounter++;
        
        ratings[ratingId] = Rating({
            id: ratingId,
            courseId: _courseId,
            studentAddress: msg.sender,
            score: _score,
            comment: _comment,
            isAnonymous: _isAnonymous,
            timestamp: block.timestamp
        });
        
        // 将评价加入课程评价列表
        courseRatings[_courseId].push(ratingId);
        
        emit RatingSubmitted(ratingId, _courseId, msg.sender, _isAnonymous);
    }
    
    /**
     * @dev 获取指定课程的所有评价ID
     * @param _courseId 课程ID
     * @return 评价ID数组
     */
    function getCourseRatingIds(uint256 _courseId) public view returns (uint256[] memory) {
        return courseRatings[_courseId];
    }
    
    /**
     * @dev 获取评价详情，根据是否匿名隐藏学生地址
     * @param _ratingId 评价ID
     */
    function getRatingDetails(uint256 _ratingId) public view returns (
        uint256 id,
        uint256 courseId,
        address studentAddress,
        uint8 score,
        string memory comment,
        uint256 timestamp
    ) {
        Rating memory rating = ratings[_ratingId];
        
        // 如果是匿名评价，并且查询者不是评价所有者或课程教师，隐藏学生地址
        bool isOwner = msg.sender == rating.studentAddress;
        bool isTeacher = msg.sender == courses[rating.courseId].teacherAddress;
        
        if (rating.isAnonymous && !isOwner && !isTeacher) {
            return (
                rating.id,
                rating.courseId,
                address(0), // 隐藏学生地址
                rating.score,
                rating.comment,
                rating.timestamp
            );
        } else {
            return (
                rating.id,
                rating.courseId,
                rating.studentAddress,
                rating.score,
                rating.comment,
                rating.timestamp
            );
        }
    }
    
    /**
     * @dev 获取教师创建的所有课程ID
     * @return 课程ID数组
     */
    function getTeacherCourses() public view onlyTeacher returns (uint256[] memory) {
        uint256 count = 0;
        
        // 首先计算该教师创建的课程数量
        for (uint256 i = 0; i < courseCounter; i++) {
            if (courses[i].teacherAddress == msg.sender) {
                count++;
            }
        }
        
        // 创建结果数组
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        // 填充结果数组
        for (uint256 i = 0; i < courseCounter; i++) {
            if (courses[i].teacherAddress == msg.sender) {
                result[index] = i;
                index++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev 获取所有活跃课程ID
     * @return 课程ID数组
     */
    function getAllActiveCourses() public view returns (uint256[] memory) {
        uint256 count = 0;
        
        // 首先计算活跃课程数量
        for (uint256 i = 0; i < courseCounter; i++) {
            if (courses[i].isActive) {
                count++;
            }
        }
        
        // 创建结果数组
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        // 填充结果数组
        for (uint256 i = 0; i < courseCounter; i++) {
            if (courses[i].isActive) {
                result[index] = i;
                index++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev 获取学生加入的所有课程ID
     * @return 课程ID数组
     */
    function getStudentCourses() public view onlyStudent returns (uint256[] memory) {
        return studentCourses[msg.sender];
    }
}