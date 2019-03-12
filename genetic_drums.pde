import beads.*;
import org.jaudiolibs.beads.*;

import processing.sound.*;

import java.io.File;

import java.util.Collections;
import java.util.Comparator;

String samplePath = "F:\\Users\\Aiden\\Documents\\Processing\\sketches\\genetic_drums\\genetic_drums\\data\\sample_packs_trimmed\\urban";
ArrayList<Sample> sampleList;
ArrayList<Float> sampleLengths;

float MAX_SAMPLE_LENGTH;
int NUM_SAMPLES;
int LOG_NUM_SAMPLES;

int maxBeats = 8;
int LOG_MAX_BEATS = int(log(maxBeats) / log(2)) + 1;

int numGenes = 8;
int populationSize = 20;
float mutationRate = 1f/numGenes; // usually one of the genes will mutate
int elementWidth, elementHeight;
int elementRows = 4, elementColumns = 5;

Element[] population;

boolean autoNextGen = false;

boolean elitist = false;
boolean noCrossover = true;
boolean randomMutation = false;
boolean shuffle = false;

int fitnessExponent = 2;

void setup() {
  size(1800, 750);
  println("MUTATION RATE: " + mutationRate);

  
  elementWidth = width/elementColumns;
  elementHeight = height/elementRows;
  
  File sampleDirectory = selectedDirectory == null ? new File(samplePath) : selectedDirectory;
  try {println(sampleDirectory.getCanonicalPath());} catch(Exception e) {}
  File[] sampleFiles = sampleDirectory.listFiles();
  sampleList = new ArrayList<Sample>();
  sampleLengths = new ArrayList<Float>();
  
  for (int i = 0; i < sampleFiles.length; i++) {
    try {
      SoundFile sf = new SoundFile(this, sampleFiles[i].getCanonicalPath());
      
      sampleList.add(new Sample(sampleFiles[i].getPath()));
      sampleLengths.add(sf.duration());
    }
    catch(Exception e) {}
  }
  
  NUM_SAMPLES = sampleList.size();
  LOG_NUM_SAMPLES = int(log(NUM_SAMPLES) / log(2)) + 1; 
  MAX_SAMPLE_LENGTH = Collections.max(sampleLengths);
   
  population = new Element[populationSize];
  for (int i = 0; i < populationSize; i++)
    population[i] = new Element();
}

Sample GetSample(int idx) {
   return sampleList.get(idx);
}

float fitness(Element element) {
  return pow(element.totalPlayTime/1000f, fitnessExponent);
}

void mutateSynth(Synth s) {  
  if (randomMutation)
    s.randomise();
  
  int mutation = int(random(4));
   
  switch (mutation) {
    case 0:
      s.changeSample(int(random(NUM_SAMPLES)));
      break;
    case 1:
      s.rate = int(random(1, maxBeats));
      break;
    case 2:
      for (int i = 0; i < random(maxBeats); i++) {
        s.decay[int(random(maxBeats))] = random(1) < 0.5 ? false : true; 
      }
      break;
    default:
      s.randomise();
      break;
   }
}

float time = millis();
float elapsedTime = 0f;

void draw() {
    elapsedTime = millis() - time;
    time = millis();
    
    for (int i = 0; i < populationSize; i++) {
       population[i].updateCanvas(); 
    }
    
    for (int i = 0; i < populationSize; i++) {
      int xOff = (i % elementColumns) * elementWidth;
      int yOff = (i / elementColumns) * elementHeight;
      
      image(population[i].canvas, xOff, yOff);
    }
    
    stroke(255);
    strokeWeight(2);
    for (int i = 0; i < elementColumns + 1; i++) {
      line(i * elementWidth, 0, i * elementWidth, height);
    }
    
    for (int i = 0; i < elementRows + 1; i++) {
      line(0, i * elementHeight, width, i * elementHeight);
    }
      
  if (autoNextGen) {
    nextGeneration();
  }
}

void nextGeneration() {
  float[] fitnesses = new float[populationSize];
  float totalFitness = 0;
    
  for (int i = 0; i < populationSize; i++) {
    float fitness = fitness(population[i]);
    totalFitness += fitness;
      
    fitnesses[i] = fitness;
  }
  
  if (totalFitness > 0f) {
    drawPopulation(fitnesses, totalFitness);
  } else {
    for (int i = 0; i < populationSize; i++) {
      population[i].randomise(); 
    }
  }
  
  for (int i = 0; i < populationSize; i++) {
    population[i].sortGenes(); 
  }
}

void drawPopulation(float[] fitnesses, float totalFitness) {
  String[][] nextPopulation = new String[populationSize][numGenes];
  
  /*
  if (elitist || noCrossover) {
    // determine fittest parent
    int fittest = 0;
    
    for (int i = 0; i < populationSize; i++) {
      if (fitnesses[i] > fitnesses[fittest]) {
        fittest = i;
      }
    }
    
    if (noCrossover) {
      nextPopulation[0] = population[fittest];
      for (int i = 1; i < populationSize; i++) {
        Element child = new Element(population[fittest]);
        // mutate
        for (int j = 0; j < numGenes; j++) {
          if (random(1) < mutationRate) {
            child.DNA.set(j, mutateSynth(child.DNA.get(j)));
          }
        }
        
        nextPopulation[i] = child;
        if (shuffle)
          Collections.shuffle(nextPopulation[i].DNA);
      }
    } else { 
      nextPopulation[0] = population[fittest];
      for (int i = 1; i < populationSize; i++) {
        Element child = new Element();
        // mutate
        for (int j = 0; j < numGenes; j++) {
          if (random(1) < mutationRate) {
            child.DNA.set(j, mutateSynth(child.DNA.get(j)));
          }
        }
      
        nextPopulation[i] = child;
        if (shuffle)
          Collections.shuffle(nextPopulation[i].DNA);
      }
    }
  } else {*/
    for (int i = 0; i < populationSize; i++) {
      Element parent1 = population[selectParent(fitnesses, totalFitness)];
      Element parent2 = population[selectParent(fitnesses, totalFitness)];
      
      nextPopulation[i] = genChild(parent1, parent2);
    }
  //}
  
  // update parameters for new generation
  for (int i = 0; i < populationSize; i++) {
    population[i].updateParameters(nextPopulation[i]);
    
    // mutate
    for (int j = 0; j < numGenes; j++) {
      if (random(1) < mutationRate) {
        mutateSynth(population[i].DNA.get(j));
      }
    }
    
    // reset fitness
    population[i].totalPlayTime = 0f;
  }
}

int selectParent(float[] fitnesses, float totalFitness) { 
    float rand = random(totalFitness);
    float cumProb = 0;
    for (int i = 0; i < fitnesses.length; i++) {
      float fitness = fitnesses[i];
      cumProb += fitness;
      if (rand <= cumProb) {
        return i;
      }
    }
    
    return 0;
}

String[] genChild(Element parent1, Element parent2) { 
  String[] child = new String[numGenes];
  
  // crossover 
  for (int i = 0; i < numGenes; i++) {
    // midpoint not ideal here as genes are ordered; prefer random choice instead
    child[i] = random(1) > 0.5 ? parent1.DNA.get(i).getEncoding() : parent2.DNA.get(i).getEncoding();
  }
    
  return child;
}

////////////////////////////////////////////////////////// MISC. UTILITIES
String XOR(String s1, String s2) {
   String s = "";
   for (int i = 0; i < s1.length(); i++) {
     s += (s1.charAt(i) == '0' ? 0 : 1) ^ (s2.charAt(i) == '0' ? 0 : 1); 
   }
   return s;
}

////////////////////////////////////////////////////////// EVENT HANDLING
int highlighted = -1;

void mousePressed() {
  try {
    highlighted = int(elementRows * mouseY/height) * elementColumns + 
                        int(elementColumns * mouseX/width);
                        
    population[highlighted].play();
  } catch(Exception e) {
    println("caught here");
  }
}

void mouseReleased() {
  population[highlighted].pause();
}

void keyPressed() {
  if (key == 'a')
    autoNextGen = !autoNextGen;
    
  if (key == ' ')
    nextGeneration();
    
  if (key == 's')
    selectFolder("Select a folder to process:", "folderSelected");
}

File selectedDirectory = null;

void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    selectedDirectory = selection;
    noLoop();
    setup();
    loop();
  }
}
