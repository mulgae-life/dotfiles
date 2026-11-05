import React from 'react';
import {Composition, staticFile} from 'remotion';
import {fade} from '@remotion/transitions/fade';
import {slide} from '@remotion/transitions/slide';
import {TransitionSeries, linearTiming} from '@remotion/transitions';
import {ScreenSlide} from './ScreenSlide';
import screensManifest from '../screens.json';

// Each transition overlaps the two adjacent sequences by this many frames.
const TRANSITION_DURATION_IN_FRAMES = 20;

// Calculate total duration in frames.
// In a TransitionSeries the outgoing and incoming sequences overlap for the
// duration of each transition, so the timeline length is the sum of sequence
// durations MINUS the sum of transition durations.
const calculateDuration = () => {
  const totalSeconds = screensManifest.screens.reduce(
    (sum, screen) => sum + screen.duration,
    0
  );
  const totalSequenceFrames = totalSeconds * screensManifest.videoConfig.fps;
  const transitionCount = Math.max(screensManifest.screens.length - 1, 0);
  return totalSequenceFrames - transitionCount * TRANSITION_DURATION_IN_FRAMES;
};

export const WalkthroughComposition: React.FC = () => {
  const {fps, width, height} = screensManifest.videoConfig;

  return (
    <TransitionSeries>
      {screensManifest.screens.flatMap((screen, index) => {
        const durationInFrames = screen.duration * fps;

        // Select transition based on screen config
        const transition =
          screen.transitionType === 'slide'
            ? slide()
            : screen.transitionType === 'zoom'
            ? fade() // Can customize with zoom effect
            : fade();

        // TransitionSeries.Transition must be a direct child of TransitionSeries,
        // placed between two Sequences (not nested inside one), and its `timing`
        // requires a timing function such as linearTiming()/springTiming().
        const elements = [
          <TransitionSeries.Sequence
            key={`${screen.id}-sequence`}
            durationInFrames={durationInFrames}
          >
            <ScreenSlide
              imageSrc={staticFile(screen.imagePath)}
              title={screen.title}
              description={screen.description}
              width={screen.width}
              height={screen.height}
            />
          </TransitionSeries.Sequence>,
        ];

        if (index < screensManifest.screens.length - 1) {
          elements.push(
            <TransitionSeries.Transition
              key={`${screen.id}-transition`}
              presentation={transition}
              timing={linearTiming({durationInFrames: TRANSITION_DURATION_IN_FRAMES})}
            />
          );
        }

        return elements;
      })}
    </TransitionSeries>
  );
};

// Register composition
export const RemotionRoot: React.FC = () => {
  const {fps, width, height} = screensManifest.videoConfig;
  const durationInFrames = calculateDuration();

  return (
    <>
      <Composition
        id="WalkthroughComposition"
        component={WalkthroughComposition}
        durationInFrames={durationInFrames}
        fps={fps}
        width={width}
        height={height}
      />
    </>
  );
};
