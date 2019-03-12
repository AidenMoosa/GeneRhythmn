class Element {
  PGraphics canvas;
  
  ArrayList<Synth> DNA;
  
  public AudioContext ac;
  
  Gain g;
  
  float totalPlayTime = 0f;
  
  Element() {
      ac = new AudioContext();   
      g = new Gain(ac, 1);
      
      canvas = createGraphics(elementWidth, elementHeight);
      
      DNA = new ArrayList<Synth>();
      for (int i = 0; i < numGenes; i++) {
        DNA.add(new Synth(ac, g));
      }
        
      sortGenes();
        
      ac.out.addInput(g);
  }
  
  void sortGenes() {
    // sort DNA by sample length, for visual purposes
    Collections.sort(DNA, new Comparator<Synth>(){
        public int compare(Synth s1, Synth s2){
          return Float.compare(sampleLengths.get(s1.sample_num), sampleLengths.get(s2.sample_num));
        }
    });       
  }
  
  Element(Element parent) {
     canvas = createGraphics(elementWidth, elementHeight);
     
     DNA = new ArrayList<Synth>();
     for (int i = 0; i < numGenes; i++) {
       DNA.set(i, parent.DNA.get(i)); 
     }
  }
  
  float playTime = 0f;
  float maxPlayTime = 1000f;
  boolean active = false;
  
  int prevBeat = -1;
  
  void play() {
    playTime = 0f;
    prevBeat = -1;
    ac.start();
    active = true;
  }
  
  void pause() {
    ac.stop();
    active = false;
  }
  
  void updateCanvas() {
    if (active) totalPlayTime += elapsedTime;
    
    canvas.beginDraw();
    
    if (active) {
      canvas.background(197);
      canvas.strokeWeight(1.25);
    } else {
      canvas.background(63);
      canvas.strokeWeight(1);
    }
    
    // draw synth beats by their rate/decay
    float beatHeight = canvas.height/numGenes;
    float beatWidth = canvas.width/maxBeats;
    canvas.colorMode(HSB, 100);
    for (int i = 0; i < numGenes; i++) {
      canvas.fill(100 * sampleLengths.get(DNA.get(i).sample_num)/MAX_SAMPLE_LENGTH, 75, 100);
      canvas.stroke(100 * sampleLengths.get(DNA.get(i).sample_num)/MAX_SAMPLE_LENGTH, 75, 50);
       for (int b = 0; b < maxBeats; b++) {
         if (b % DNA.get(i).rate == 0 && DNA.get(i).decay[b / DNA.get(i).rate]) {
            canvas.strokeWeight(b == int(playTime / maxPlayTime * maxBeats) ? 2 : 1);
            //canvas.rect(b * beatWidth, i * beatHeight, beatWidth * (int(relFreqs.get(DNA.get(i).sample_num)) + 1) / 5, beatHeight, 5, 0, 5, 0);
            canvas.rect(b * beatWidth, i * beatHeight, beatWidth * (sampleLengths.get(DNA.get(i).sample_num) / MAX_SAMPLE_LENGTH), beatHeight, 5, 0, 5, 0);
            canvas.strokeWeight(active ? 1.25 : 1);
         }
       }
    }
    canvas.colorMode(RGB, 255);

    if (active) {
      float barProgress = playTime / maxPlayTime;
      
      // update beat number if necessary
      int beat = int(barProgress * maxBeats);
      if (beat != maxBeats && beat != prevBeat) {
        for (int i = 0; i < numGenes; i++) {
          DNA.get(i).beatChanged(beat); 
        }
        
        prevBeat = beat;
      }
      
      // draw sweeping line to show elapsed time
      canvas.stroke(200, 50, 50);
      canvas.line(canvas.width * barProgress, 0, canvas.width * barProgress, canvas.height);
      
      playTime += elapsedTime;
      if (playTime > maxPlayTime) {
        playTime = 0f;
        // stop long samples from playing
        ac.reset();
        for (int i = 0; i < numGenes; i++) {
          DNA.get(i).sp.reset(); 
        }
      }
    }
    
    canvas.endDraw();
  }
  
  String[] getGenes() {
    String[] genes = new String[numGenes];
    for (int i = 0; i < numGenes; i++) {
       genes[i] = DNA.get(i).getEncoding();
    }
    return genes;
  }
  
  void updateParameters(String[] genes) {
    for (int i = 0; i < numGenes; i++) {
      DNA.get(i).decodeSynth(genes[i]); 
    }
  }
  
  void randomise() {
    for (Synth s : DNA) s.randomise(); 
  }
}
