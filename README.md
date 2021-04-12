# Traffic-Light-Controller-FPGA-VHDL
## Introduction
Currently vehicles are one of the main enablers of movement from one place to another. These vehicles, if not properly managed, can cause serious damages on health, property as well as can lead to death. The main management mechanisms which are used to control vehicles’ movements and minimize accidents are traffic lights. Traffic lights are control signals which display messages via lights about what the driver and/or a pedestrian should do in order to avoid accidents and make movement from place to place easy. <br/>

This project is for designing and implementing a traffic light controller using the Basys3 board and additional circuitry if needed. The controller implementation is for the road intersection shown in Fig.1 below. The first street, Street A, runs North-South, Street B runs East-West, and Street C joins the main intersection from South-East. The given specifications or requirements for the project implementation are:<br/>
    • There are five sets of traffic lights, facing cars coming from A North, A South, B East, B West, and C South-East, respectively.<br/> 
    • The red, yellow, and green lights on streets A North, A South, B East and B West should be augmented with green and yellow turn arrows.<br/>
    • The normal sequencing of lights facing the cars coming from A north and A South is green arrow, yellow arrow, traffic light green, traffic light yellow, traffic light red, and repeat. But the green light should also be illuminated together with the green arrow for both.<br/>
    • The turn arrows on street A north and south should be accompanied by all other roads being showing red light.<br/>
    • Car detector sensors should be installed on C Street and both West and East sides of Street B which will enable the turn arrows on B Street and the lights on C Street. These sensors should be represented by buttons on the Basys3 board.<br/>
    • A timer generates a long interval signal TL which is used to control the time duration that green and red lights will be lit and a short interval signal TS which is used to determine the time duration of yellow, green arrow and yellow arrow being in lit condition. These durations should be modified from the keypad by entering a value between 1 to 10 seconds.<br/>
    • Both TL and TS are set/reset by an ST signal. The C Street lights cycle from red to green only if the embedded car sensor indicates that a car is waiting. The lights cycle to yellow and then red as soon as no cars are waiting. The maximum duration that the C Street green light is lit on is TL. <br/>
    • The state of the traffic signals should be seen on a connected LCD screen. <br/>
    • Lights on Basys3 board are used to represent the traffic lights.<br/>
    • A connected VGA monitor should show:<br/>
            ▪ The remaining value of the long timer, TL.<br/>
            ▪ The color of the traffic lights on streets A, B and C at that particular state.<br/>

