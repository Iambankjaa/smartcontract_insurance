pragma solidity >=0.5.0 <0.7.0;

contract Insurance {
    // uint256 lastRun;
    uint256 Opentime;
    uint timeContactstart;

    uint public value;
    uint public claim;
    uint public claimover200percent;
    uint public stack;
    
    address payable public Insurer;
    address payable public customer;
    // mapping (address => uint) public insuranceBalances;

    string public hash_video = 'please submit hash ipfs your video';
    string public hash_video_evidence = 'please submit hash ipfs your video';
    
    enum State { Created, Locked, Contactstart, customerRelease, BTYRelease, Inactive }
    // The state variable has a default value of the first member, `State.created`
    State public state;

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyCustomer() {
        require(
            msg.sender == customer,
            "Only buyer can call this."
        );
        _;
    }

    modifier onlyInsurer() {
        require(
            msg.sender == Insurer,
            "Only Insurer can call this."
        );
        _;
    }

    modifier inState(State _state) {
        require(
            state == _state,
            "Invalid state."
        );
        _;
    }
    constructor() public payable {
        Insurer = msg.sender;
        value = 1000000000000000000; //wei
        claim = 0;
        stack = 0;
    }

    function abort()//ถ้าเจ้าประกันต้องการยกเลิกการทำประกัน
        public
        onlyInsurer
        inState(State.Created)
    {
        state = State.Inactive;
        Insurer.transfer(address(this).balance);
    }
    
    function Timeout()//ถ้าเจ้าของประกระไม่ยอมกดยอมรับภายในเวลาที่กำหนดให้คืนเงินได้
        public
        onlyCustomer
        inState(State.Locked)
    {
        require(block.timestamp - timeContactstart > 5 minutes, 'wait Timeout');
        state = State.customerRelease;
    }
    
    function confirm_startcontract(string memory _hash_video)//ใส่ค่าhashวิดีโอละโอนตังทำประกันรอเจ้าของยอมรับ
        public
        inState(State.Created)
        condition(msg.value == (value))
        payable
    {
        customer = msg.sender;
        state = State.Locked;
        
        timeContactstart = block.timestamp;
        
        hash_video = _hash_video;
    }
    
    function confirm_contractstart() //เจ้าของประกันกดยอมรับแล้วเริ่มทำประกัน
        public
        onlyInsurer
        inState(State.Locked)
        // condition(msg.value == (value))
        // payable
    {
        state = State.Contactstart;
        
        timeContactstart = block.timestamp;
        
    }
    
    function check_time_contacrt() //เจ้าของประกันกดยอมรับแล้วเริ่มทำประกัน
        public
        view
        inState(State.Contactstart)
        returns (uint)
        // condition(msg.value == (value))
        // payable
    {
        // state = State.Contactstart;
        // insuranceBalances[customer] = lastRun + 730 hours;
        // lastRun = block.timestamp;
        return (30-(block.timestamp-(timeContactstart))/86400);
    }
    function restart_contract() //ต่ออายุประกัน
        public
        onlyCustomer
        inState(State.Contactstart)
        condition(msg.value == (value))
        payable
    {
        require(block.timestamp - timeContactstart > 5 seconds, 'Need to wait 30 Day');
            if (block.timestamp - timeContactstart > 5 minutes){
                state = State.Inactive;
            }
            if (claimover200percent ==0){
                    stack = 0;
            }
        timeContactstart = block.timestamp;
        claim = 0;
        claimover200percent = 0;
        Insurer.transfer(msg.value);
    }


    function refundCustomer()//ลูกค้าเอาเหรียญออกกรณีเจ้าของไม่ยอมรับ
        public
        onlyCustomer
        inState(State.customerRelease)
    {
        state = State.Inactive;
        customer.transfer(address(this).balance);
    }
    
    function withdraw_Insurer()//เจ้าของประกันเอาเหรียญออก
        public
        onlyInsurer
        inState(State.Contactstart)
    {
    
        Insurer.transfer(address(this).balance);
    }
    
    function send_evidence(string memory _hash_video_evidence)//ใส่ค่าhashวิดีโอหลักฐานรอเจ้าของยอมรับ
        public
        inState(State.Contactstart)
    {
        
        hash_video_evidence = _hash_video_evidence;
    }
    
    function incorrect_claimmoney()//โอนเหรียญค่าทดแทนค่าเสียหายให้ลูกค้า กรณีลูกค้าเป็นฝ่ายผิด
        public
        payable
        onlyInsurer
        inState(State.Contactstart)
    {
        claim = claim + msg.value;
        if (claim >value*2){ //เคลมเกิน 200 จะทำการเพิ่มเบี้ยประกันตามการเคลมเกิน200%ตามจำนวนปีที่ติดต่อกัน
            claimover200percent ++;
            if (claimover200percent==1){
            stack ++;
                if (stack == 1){ //ปีแรก 20 %
                    value = ((value*20)/100)+value;
                }
                if (stack == 2){ //ปีสอง 30 %
                    value = ((value*30)/100)+value;
                }
                 if (stack == 3){ //ปีสาม 40 %
                    value = ((value*40)/100)+value;
                }
                if (stack > 3){ //สี่ปีเป็นต้นไป 50 %
                    value = ((value*50)/100)+value;
                }
                claimover200percent = claimover200percent+1;
            }
        }
        customer.transfer(msg.value);
    }
    
    function correct_claimmoney()//โอนเหรียญค่าทดแทนค่าเสียหายให้ลูกค้า กรณีลูกค้าเป็นฝ่ายถูก
        public
        payable
        onlyInsurer
        inState(State.Contactstart)
    {
        customer.transfer(msg.value);
    }
    
    // function update_value()
    //     public
    //     onlyInsurer
    //     inState(State.Contactstart)
    //     // condition(claimover200percent ==1)
    //     payable
    //     {
    //         if (claimover200percent==1){
    //         stack ++;
    //             if (stack == 1){
    //                 value = ((value*20)/100)+value;
    //             }
    //             if (stack == 2){
    //                 value = ((value*30)/100)+value;
    //             }
    //              if (stack == 3){
    //                 value = ((value*40)/100)+value;
    //             }
    //             if (stack > 3){
    //                 value = ((value*50)/100)+value;
    //             }
    //             claimover200percent = claimover200percent+1;
    //         }
    //     }
    
    // function uploadVideoyourccar(string memory _hash_video) 
    //     public 
    //     onlyCustomer
    //     inState(State.Locked)
    //     condition(msg.value == (value))
    //     payable
    // {
    //     hash_video = _hash_video;
    // }
}