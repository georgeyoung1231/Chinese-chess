import processing.serial.*;
import gausstoys.core.*;
import ddf.minim.*;
import gifAnimation.*;
import de.looksgood.ani.*;

// Libraries
// AudioPlayer player;
// Minim minim; // audio context
GaussSense gs;

// Image
PImage bg_img;
Gif highlight0Gif;
Gif highlight1Gif;
final String img_path_prefix = "ChineseChessNew-";
final String bg_img_path = img_path_prefix + "Board.png";
PImage img;

// Constant
final int window_width = 1000;
final int window_height = 625;
final int row = 4;
final int col = 8;
final int dist = 125; 
final int chess_size = 90;
final int chess_num = row*col;
final int token_num = 14;
final int rank_arr[] = {0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6};
final int tags[][] = {{73, 12}, {105, -100}, {-119, 111}, {-87, -82}, {-119, -65}, {9, -26},   {-103, 55}, // Red team rank from 0 to 6  
                      {89, 48}, {-55, -68},  {-39, 74},   {-7, -118}, {-23, -98},  {-39, 90}, {57, -106}};  // Blue team rank from 6 to 0
// int tags[][] = {{-103, 55}, {9, -26}, {-119, -65}, {-87, -82}, {-119, 111}, {105, -100}, {73,12},
//                {57, -106}, {-39, 90}, {-23, -98}, {-7, -118}, {-39, 74}, {-55, -68}, {89, 48}};
float ani_x = 0, ani_y = 0;
final PVector start = new PVector(15,145);
final PVector board_pos[][] = new PVector[row][col];

// Status
Direction direction;
boolean isOnStage = false;
boolean victory = false;
boolean key_mode_team = false;
int key_mode_rank;

// Chess, Board and Token
Chess chessList[] = new Chess[chess_num];
Board boardList[][] = new Board[row][col];
GaussToken tokenList[] = new GaussToken[token_num];
GaussToken lastToken = null;


class GaussToken {
  final boolean team;
  final int rank;
  final int tag[] = new int[2];
  GaussToken (boolean team, int rank, int tag1, int tag2){
    this.team = team;
    this.rank = rank;
    this.tag[0] = tag1;
    this.tag[1] = tag2;
  }
}

class Board {
  PVector pos;
  boolean isEmpty;
  Chess who;
}

class Chess {
  PVector pos;
  boolean team;
  int rank;
  boolean isFlip;
  boolean isDead;
  boolean isMoving;

  public Chess(boolean team, int rank){
    this.team = team;
    this.isDead = false;
    this.isFlip = false;
    this.rank = rank;
    this.pos = null;
    this.isMoving = false;
  }
  public void setPosition(PVector pos){
    this.pos = pos;
  }

}

void setup() {
  smooth();
  size(window_width, window_height);
  bg_img = loadImage(bg_img_path);
  
  highlight0Gif = new Gif(this, "ChineseChess-Highlight3.gif");
  highlight0Gif.loop();
  highlight1Gif = new Gif(this, "ChineseChess-Highlight3.gif");
  highlight1Gif.loop();
  
  //Initialize the Music Player
  // minim = new Minim(this);
  
  //Initialize the GaussSense
  GaussSense.printSerialPortList();
  gs = new GaussSense(this, GaussSense.GSType.GAUSSSENSE_STAGE, Serial.list()[Serial.list().length - 1], 115200);
  gs.setVibrator(false);

  // set chessList
  for (int i = 0; i < rank_arr.length; i++) {
    chessList[i] = new Chess(true, rank_arr[i]);
    chessList[rank_arr.length + i] = new Chess(false, rank_arr[i]);
  }


  // set boardList
  for (int i = 0; i < row; i++) {
    for (int j = 0; j < col; j++) {
      boardList[i][j] = new Board();
      boardList[i][j].pos = new PVector(start.x+dist*j, start.y+dist*i);
      boardList[i][j].isEmpty = false;
      // randomly pick chess who doesn't have position to put in this grid
      int random_num;
      do{
        random_num = (int)random(chess_num);
      }while(chessList[random_num].pos != null);
      chessList[random_num].setPosition(new PVector(i,j));
      boardList[i][j].who = chessList[random_num];
    }
  }

  // set tokenList
  for (int i = 0; i < token_num/2; i++) {
    tokenList[i] = new GaussToken(true, i, tags[i][0], tags[i][1]);
    tokenList[token_num/2 + i] = new GaussToken(false, i, tags[token_num/2 + i][0], tags[token_num/2 + i][1]);
  }
  
  Ani.init(this);
}

void draw() {
  background(0);
  image(bg_img, 0, 0, window_width, window_height);
  // GaussStage
  float thld = 5; //Unit: Gauss
  //Get bipolar midpoint data
  int upsampleFactor = 5;
  gs.setUpsampledData2D(this.width, this.height, upsampleFactor);
  GData pBipolarMidpoint = gs.getBipolarMidpoint(thld);
  
  int tokenOnStage = -1;
  boolean teamOnStage = false;
  int rankOnStage = -1;

  if(gs.isTagOn()) {
    // GaussToken is on the GaussStage 
    int[] tag = gs.getTagID();
    String str = "Tag: "+tag[0]+", "+tag[1]+", "+tag[2]+", "+tag[3]+", "+tag[4];
//    println(str);
    float angleInRad = (float) pBipolarMidpoint.getAngle(); //Get the angle of roll. Unit: Rad
    int angleInDegree = (int) degrees(angleInRad); //Turn the rad into degree
    angleInDegree = angleInDegree+180; // map degree to 0~360
//    println(angleInDegree);
    
    if (angleInDegree > 225 && angleInDegree < 315)
      direction = Direction.UP;
    else if (angleInDegree > 315 || angleInDegree < 45)
      direction = Direction.RIGHT;
    else if (angleInDegree > 45 && angleInDegree < 135)
      direction = Direction.DOWN;
    else 
      direction = Direction.LEFT;
//    println(angleInDegree + ":" + direction);

    tokenOnStage = whosOnStage(tag);
    
    if(tokenOnStage != -1){
      teamOnStage = tokenList[tokenOnStage].team;
      rankOnStage = tokenList[tokenOnStage].rank;
    
//      println("Now on GaussStage: token" + tokenOnStage + " team:" + teamOnStage + "rank: " + rankOnStage);

      flipSameRankChess(teamOnStage, rankOnStage);
      if(lastToken == tokenList[tokenOnStage] && isOnStage == false){
        for (int i = 0; i < chess_num; i++) {
          if (chessList[i].rank == rankOnStage && chessList[i].team == teamOnStage) {
            switch (direction) {
              case UP: 
                chess_move(chessList[i], new PVector(-1, 0));
                break;
    
              case DOWN: 
                chess_move(chessList[i], new PVector(1, 0));
                break;
    
              case LEFT: 
                chess_move(chessList[i], new PVector(0, -1));
                break;
    
              case RIGHT: 
                chess_move(chessList[i], new PVector(0, 1));
                break;
    
              default: 
                break;
            }
          }
        }
      }

      isOnStage = true;
      lastToken = tokenList[tokenOnStage];
    }
    
    
  }
  else if(isOnStage == true){
    // Once ever on stage, now jump down
    println("temporary leave stage b4 making decision.");
    println("decided decision is: " + direction);
    isOnStage = false;
  }
  
  // Draw Chess Images
  for (int i = 0; i < chess_num; i++) {
    int x = (int)chessList[i].pos.x;
    int y = (int)chessList[i].pos.y;
    if (!chessList[i].isFlip) {
      pushStyle ();
      img = loadImage (img_path_prefix + "000.png");
      image (img, boardList[x][y].pos.x, boardList[x][y].pos.y, chess_size, chess_size);
      popStyle ();
    }
    else if (!chessList[i].isDead) {
      // Draw ALL Chesses
      int team = chessList[i].team?1:0;
      String str = img_path_prefix + team + chessList[i].rank +".png";
      if (gs.isTagOn() && chessList[i].rank == rankOnStage && chessList[i].team == teamOnStage){
        pushStyle ();
        if(teamOnStage == false)
          image (highlight0Gif, boardList[x][y].pos.x-10, boardList[x][y].pos.y-10, chess_size+20, chess_size+20);
        else
          image (highlight1Gif, boardList[x][y].pos.x-10, boardList[x][y].pos.y-10, chess_size+20, chess_size+20);
        popStyle ();
      }
      if(chessList[i].isMoving){
        if(ani_x == boardList[x][y].pos.x && ani_y == boardList[x][y].pos.y)
          chessList[i].isMoving = false;
        img = loadImage (str);
        image (img, ani_x, ani_y, chess_size, chess_size);
      }
      else{
        img = loadImage (str);
        image (img, boardList[x][y].pos.x, boardList[x][y].pos.y, chess_size, chess_size);
      }
      
      // Draw Only ONE Diretion Indicator
      if (gs.isTagOn() && chessList[i].rank == rankOnStage && chessList[i].team == teamOnStage) {
    
        switch (direction) {
          case RIGHT: 
            img = loadImage (img_path_prefix + "right.png");
            break;
          
          case UP:
            img = loadImage (img_path_prefix + "up.png");
            break;
          
          case LEFT: 
            img = loadImage (img_path_prefix + "left.png");
            break;
          
          case DOWN: 
            img = loadImage (img_path_prefix + "down.png");
            break;
          
          default: 
            break;
        }
        image (img, boardList[x][y].pos.x, boardList[x][y].pos.y, chess_size, chess_size);
      }  
    }
  }

  // Game Result
  int who_won = checkWin(); 
  if((who_won != -1) && !victory){
      // player = minim.loadFile("victory.mp3", 2048);
      // player.play();
      println("team" + who_won + " won the game!");
      victory = true;
  }
}

boolean chess_move(Chess who, PVector direction){
  // new possible position (x, y)
  int x = (int)(who.pos.x + direction.x);
  int y = (int)(who.pos.y + direction.y);
  
  if(x < row && y < col && x >= 0 && y >= 0){
    // inside the board
    if(boardList[x][y].isEmpty){
      // next grid is empty/movable
<<<<<<< HEAD
      // player = minim.loadFile("marching.mp3", 2048);
      // player.play();
=======
      player = minim.loadFile("marching.mp3", 2048);
      player.play();
>>>>>>> a019b61396fe6190a8b7059b1f96eee06e88d7e0
      ani_x = boardList[(int)who.pos.x][(int)who.pos.y].pos.x;
      ani_y = boardList[(int)who.pos.x][(int)who.pos.y].pos.y;
      Ani.to(this, 1.5, "ani_x", boardList[x][y].pos.x);
      Ani.to(this, 1.5, "ani_y", boardList[x][y].pos.y);
<<<<<<< HEAD
      who.isMoving = true;
=======
      who.isMoving =   ;
>>>>>>> a019b61396fe6190a8b7059b1f96eee06e88d7e0
      boardList[(int)who.pos.x][(int)who.pos.y].isEmpty = true;
      boardList[(int)who.pos.x][(int)who.pos.y].who = null;
      who.pos.x = x;
      who.pos.y = y;
      boardList[x][y].who = who;
      boardList[x][y].isEmpty = false;
      println("moved");
      return true;
    }
    else if((boardList[x][y].who!=null) && chess_attack(who, boardList[x][y].who)){
      // attack successfully
<<<<<<< HEAD
      // player = minim.loadFile("eat.wav", 2048);
      // player.play();
      println(boardList[x][y].who.team + "r" + boardList[x][y].who.rank + " is killed by " + who.team + "r" + who.rank);
=======
      player = minim.loadFile("eat.wav", 2048);
      player.play();
>>>>>>> a019b61396fe6190a8b7059b1f96eee06e88d7e0
      ani_x = boardList[(int)who.pos.x][(int)who.pos.y].pos.x;
      ani_y = boardList[(int)who.pos.x][(int)who.pos.y].pos.y;
      Ani.to(this, 1.5, "ani_x", boardList[x][y].pos.x);
      Ani.to(this, 1.5, "ani_y", boardList[x][y].pos.y);
      who.isMoving = true;
      boardList[(int)who.pos.x][(int)who.pos.y].isEmpty = true;
      boardList[(int)who.pos.x][(int)who.pos.y].who = null;
      who.pos.x = x;
      who.pos.y = y;
      boardList[x][y].who = who;
      boardList[x][y].isEmpty = false;
      
      gs.setVibrator(true);
//      delay(1000);
      gs.setVibrator(false);
      println("attacked");
      return true;
    }
    else{
      return false;
    }
  }
  return false;
}

boolean chess_attack(Chess killer, Chess victim){
  // return attack success or not
  if (killer.isFlip && victim.isFlip && killer.team != victim.team) {
    if ((killer.rank >= victim.rank) && !(killer.rank == 6 && victim.rank == 0)) {
      // kill the smaller except king cannot kill the smallest
      victim.isDead = true;
    }
    else if (killer.rank == 0 && victim.rank == 6) {
      // kill the king
      victim.isDead = true;   
    }
  }
  return victim.isDead;
}

void flipSameRankChess (boolean team, int rank) {
  for (int i = 0; i < chess_num; i++) {
    
    if (chessList[i].team == team && chessList[i].rank == rank) {
      if (!chessList[i].isFlip) {
        // player = minim.loadFile("flip.wav", 2048);
        // player.play();
        chessList[i].isFlip = true;
        
      }
    }
  }
}

// Return the found index of tags array
int whosOnStage (int readtag[]) {
  for (int i = 0; i < token_num; i++) {
    if (readtag[0] == tokenList[i].tag[0] && readtag[1] == tokenList[i].tag[1]){
      return i;
    }
  }
  return -1;
}

// Victory judgement
int checkWin () {
  boolean team0_win = false;
  boolean team1_win = false;
  for (int i = 0; i < chess_num; i++) {
    if(!chessList[i].isDead && !chessList[i].team){
      team0_win = true;
    }else if(!chessList[i].isDead && chessList[i].team){
      team1_win = true;
    }
  }
  if (!team0_win)
    return 0;
  else if (!team1_win)
    return 1;
  return -1;
}

// Key mode for debugging
void keyPressed () { 
  if (key >= '0' && key <= '6') {
    key_mode_rank = Character.getNumericValue(key);;
    flipSameRankChess(key_mode_team, key_mode_rank);  
  }
  else if (key == 't') {
    key_mode_team = !key_mode_team;
    println ("change team to: " + key_mode_team);
  }
  else if (key == CODED) {
    for (int i = 0; i < chess_num; i++) {
      if (chessList[i].rank == key_mode_rank && chessList[i].team == key_mode_team) {
        switch (keyCode) {
          case RIGHT:
            chess_move(chessList[i], new PVector(0, 1));
            break;
          
          case LEFT: 
            chess_move(chessList[i], new PVector(0, -1));
            break;
          
          case UP:
            chess_move(chessList[i], new PVector(-1, 0));
            break;
          
          case DOWN: 
            chess_move(chessList[i], new PVector(1, 0));
            break;
          
          default:
            break;
        }
      }
    }
  }
  else if (key == ENTER) {//Press Enter for re-calibration
    if (gs != null) {
      gs.redoCalibration();
      gs.setLED(0);
      gs.setVibrator(false);
      gs.setServo(0);
    }
  }
} 

void mouseReleased() {
    // animate the variables x and y in 1.5 sec to mouse click position
    
<<<<<<< HEAD
}
=======
}
>>>>>>> a019b61396fe6190a8b7059b1f96eee06e88d7e0
