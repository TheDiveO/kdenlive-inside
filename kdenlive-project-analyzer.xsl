<?xml version="1.0"?>
<!--
     Kdenlive Project XML Analyzer
     (c) 2016 Harald Albrecht

     For more details about the XML content of Kdenlive projects, please
     see: http://thediveo-e.blogspot.com/2016/07/inside-kdenlive-projects.html

     This program is free software: you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation, either version 3 of the License, or
     (at your option) any later version.

     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.

     You should have received a copy of the GNU General Public License
     along with this program.  If not, see <http://www.gnu.org/licenses/>.
  -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Produce HTML5 document on an XSLT processor which does not
         support disable-output-escaping in order to generate the
         HTML5 !DOCTYPE. HTML5 thus defines a legacy doctype.
      -->
    <xsl:output method="html"
                doctype-system="about:legacy-compat"
                encoding="utf-8"
                indent="yes"/>

    <xsl:variable name="version" select="'0.9.8'"/>


    <!-- We later need this key to group clips by their "name", where "name" is
         a slightly involved concept. A clip name is either its name as explicitly
         assigned by the user, or the filename+extension, but without its file path.
      -->
    <xsl:key name="clipkey" match="producer" use="substring(concat(replace(property[@name='resource'],'.*/',''),property[@name='kdenlive:clipname']),1,1)"/>


    <!-- Parameters to this XSLT stylesheet -->
    <xsl:param name="project-name"/><!-- project URI/file name -->


    <!-- Pull in all the required modules -->
    <xsl:include href="kpa-utils.xsl"/>
    <xsl:include href="kpa-timeline-utils.xsl"/>
    <xsl:include href="kpa-main.xsl"/>
    <xsl:include href="kpa-project-information.xsl"/>
    <xsl:include href="kpa-project-statistics.xsl"/>
    <xsl:include href="kpa-project-bin.xsl"/>
    <xsl:include href="kpa-clips.xsl"/>
    <xsl:include href="kpa-tracks.xsl"/>
    <xsl:include href="kpa-transitions.xsl"/>




    <!-- Clip-type specific icons -->
    <!-- generic or A/V clip icon -->
    <xsl:template name="av-clip-icon">
        <i class="fa fa-file-video-o" title="A/V clip"/>
    </xsl:template>


    <!-- audio clip icon -->
    <xsl:template name="audio-clip-icon">
        <i class="fa fa-file-audio-o" title="audio clip"/>
    </xsl:template>


    <!-- image clip icon -->
    <xsl:template name="image-clip-icon">
        <i class="fa fa-picture-o" title="image clip"/>
    </xsl:template>


    <!-- image sequence clip icon -->
    <xsl:template name="image-sequence-clip-icon">
        <span title="image sequence clip">
            <i class="fa fa-picture-o" title="image sequence clip"/>&#8201;<i class="fa fa-picture-o"/>&#8201;&#8226;&#8226;&#8226;
        </span>
    </xsl:template>


    <!-- title clip icon -->
    <xsl:template name="title-clip-icon">
        <i class="fa fa-font" title="audio clip"/>
    </xsl:template>


    <!-- color clip icon -->
    <xsl:template name="color-clip-icon">
        <span style="font-size:50%; letter-spacing: -0.3em;" aria-hidden="true" title="color clip">
            <i class="fa fa-circle" style="color: #c00;"/>
            <i class="fa fa-circle" style="color: #0c0;"/>
            <i class="fa fa-circle" style="color: #00c;"/>
        </span>
    </xsl:template>


    <!-- More icon definitions -->
    <!-- generic transition icon -->
    <xsl:template name="transition-icon">
        <i class="fa fa-clone in-track"/>
    </xsl:template>


    <!-- generic video track icon -->
    <xsl:template name="video-track-icon">
        <xsl:param name="title" select="'video track'"/>
        <i class="fa fa-film in-track" title="{$title}"/>
    </xsl:template>


    <!-- generic audio track icon -->
    <xsl:template name="audio-track-icon">
        <xsl:param name="title" select="'audio track'"/>
        <i class="fa fa-volume-up in-track" title="{$title}"/>
    </xsl:template>


    <!-- Show an error icon -->
    <xsl:template name="error-icon">
        <i class="fa fa-exclamation-triangle error"/>
    </xsl:template>


    <!-- Show a warning icon -->
    <xsl:template name="warning-icon">
        <i class="fa fa-exclamation-circle warning"/>&#160;
    </xsl:template>




    <!-- Show transparent track state icon -->
    <xsl:template name="transparent-track-icon">
        <i class="fa fa-delicious anno-composite" aria-hidden="true" title="transparent track"/>&#160;
    </xsl:template>


    <!-- Show opaque track state icon -->
    <xsl:template name="opaque-track-icon">
        <i class="fa fa-square-o anno-opaque" aria-hidden="true" title="opaque track"/>&#160;
    </xsl:template>


    <!-- List all the (timeline) tracks that are defined in this Kdenlive project.
         We list/show the tracks in the usual Kdenlive timeline layout, that is,
         from the topmost track down to the bottommost track, in this order. On
         purpose, we list *all* tracks, including the built-in and hidden "Black"
         track that Kdenlive automatically includes with each project.
      -->
    <xsl:template name="list-all-tracks">
        <!-- Kdenlive's tracks are referenced as <tracks> elements inside the
             main <tractor> with id "maintractor". However, the Kdenlive
             tracks themselves are then represented as <playlists>. -->
        <xsl:if test="count(/mlt/playlist[@id='black_track']) != 1">
            <xsl:call-template name="error-icon"/>&#160;The hidden built-in internal "Black" track is missing.
        </xsl:if>

        <xsl:call-template name="show-timeline-compositing-info"/>

        <p><xsl:value-of select="$num-timeline-user-tracks"/> <span class="anno"> (<i>+1 hidden built-in "Black" track</i>)</span> timeline tracks:</p>
        <ul class="tracks">
            <xsl:for-each select="$timeline-tracks">
                <!-- We only need this loop for counting MLT track indices...! -->
                <li>
                    <xsl:call-template name="show-track-info">
                        <xsl:with-param name="mlt-track-idx" select="$num-timeline-tracks - position()"/>
                    </xsl:call-template>
                </li>
            </xsl:for-each>
        </ul>

        <!-- Check the hidden built-in black track #0 to match the overall
             timeline length as calculated on the basis of all user tracks,
             with indices from #1 on.
          -->
        <xsl:variable name="black-track-len">
            <xsl:call-template name="calc-track-length">
                <xsl:with-param name="mlt-track-idx" select="0"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="timeline-len">
            <xsl:call-template name="max-timeline-length"/>
        </xsl:variable>

        <p>
            The overall timeline length is
            <xsl:call-template name="show-timecode">
                <xsl:with-param name="frames">
                    <xsl:value-of select="$timeline-len"/>
                </xsl:with-param>
            </xsl:call-template>.
        </p>

        <p class="anno">
            (<i>Please note that for projects edited with Kdenlive 16.07.xx, 16.08, or later, the hidden built-in "Black" track is always one frame longer than the overall timeline length. The calculation of the overall timeline length is only taking user-visible timeline tracks into the overall length calculation. For older projects, the length of the "Black" tracks equals that of the overall timeline length.</i>)
        </p>

        <xsl:if test="($timeline-len != $black-track-len) and ($timeline-len != ($black-track-len - 1))">
            <xsl:call-template name="error-icon"/>&#160;
            <span class="error">
                Error: the hidden built-in "Black" track (<xsl:call-template name="show-timecode"><xsl:with-param name="frames" select="$black-track-len"/></xsl:call-template>) is
                <xsl:choose>
                    <!-- The black track actually seems to be always one frame longer
                         than the overall timeline length; probably so users can
                         add or insert clips at the end after the last clip?
                      -->
                    <xsl:when test="$timeline-len &gt; ($black-track-len - 1)">
                        shorter
                    </xsl:when>
                    <xsl:otherwise>
                        longer
                    </xsl:otherwise>
                </xsl:choose>
                than the overall timeline length (<xsl:call-template name="show-timecode"><xsl:with-param name="frames" select="$timeline-len"/></xsl:call-template>)!
            </span>
        </xsl:if>

        <p>
            The bottommost <i>video</i> track is track
            "<xsl:call-template name="show-track-title">
                <xsl:with-param name="mlt-track-idx" select="$timeline-lowest-video-track"/>
                <xsl:with-param name="class" select="''"/>
            </xsl:call-template>"
            <span class="anno">(<i>MLT track index: <xsl:value-of select="$timeline-lowest-video-track"/></i>)</span>
        </p>
    </xsl:template>


    <!-- ### -->
    <xsl:template name="calc-track-transitions-end">
        <xsl:param name="mlt-track-idx"/>

        <xsl:variable name="user-transitions" select="/mlt/tractor[@id='maintractor']/transition[not(property[@name='internal_added']) and property[@name='b_track'] = $mlt-track-idx]"/>

        <xsl:choose>
            <xsl:when test="count($user-transitions) = 0">
                0
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="max($user-transitions/@out)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="show-track-transitions-end">
        <xsl:param name="mlt-track-idx"/>

        <xsl:call-template name="show-timecode">
            <xsl:with-param name="frames">
                <xsl:call-template name="calc-track-transitions-end">
                    <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <xsl:template name="track-total-length-timecode">
        <xsl:param name="mlt-track-idx"/>

        <xsl:variable name="len-by-clip">
            <xsl:call-template name="calc-track-length">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="len-by-transition">
            <xsl:call-template name="calc-track-transitions-end">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$len-by-clip &gt;= $len-by-transition">
                <span title="track length, determinded by last clip">
                    <xsl:call-template name="show-timecode">
                        <xsl:with-param name="frames">
                            <xsl:value-of select="$len-by-clip"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span title="track length, as determined by overhanging transition">
                    <xsl:call-template name="show-timecode">
                        <xsl:with-param name="frames">
                            <xsl:value-of select="$len-by-transition"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- Show appropriate icon depending on type of track.
      -->
    <xsl:template name="show-track-icon">
        <xsl:param name="mlt-track-idx"/>

        <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]"/>
        <xsl:variable name="hide" select="$track-ref/@hide"/>
        <xsl:variable name="track" select="/mlt/playlist[@id=$track-ref/@producer]"/>

        <!-- Watch the builtin nameless, but not @id-less "Black" track!
          -->
        <xsl:choose>
            <!-- a user named track -->
            <xsl:when test="$track/property[@name='kdenlive:track_name']">
                <!-- Track type icon: video or audio; this information is found inside the
                     <playlist> track element.
                  -->
                <span class="track-icon">
                    <xsl:choose>
                        <xsl:when test="$track/property[@name='kdenlive:audio_track']">
                            <xsl:call-template name="audio-track-icon"><xsl:with-param name="title" select="concat('audio track no. ', $mlt-track-idx)"/></xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="video-track-icon"><xsl:with-param name="title" select="concat('video track no. ', $mlt-track-idx)"/></xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
            </xsl:when>
            <!-- an unnamed (internal) track -->
            <xsl:otherwise>
                <span class="track-icon anno" aria-hidden="true" title="builtin &#34;Black&#34; track"><i class="fa fa-eye-slash in-track"/></span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- Show title of a track.
      -->
    <xsl:template name="show-track-title">
        <xsl:param name="mlt-track-idx"/>
        <xsl:param name="class" select="'track-title'"/>

        <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]"/>
        <xsl:variable name="track" select="/mlt/playlist[@id=$track-ref/@producer]"/>

        <!-- Watch the builtin nameless, but not @id-less "Black" track!
          -->
        <xsl:choose>
            <!-- a user named track -->
            <xsl:when test="$track/property[@name='kdenlive:track_name']">
                <!-- The user-visible track name -->
                <span class="{$class}">
                    <b><xsl:value-of select="$track/property[@name='kdenlive:track_name']"/></b>
                </span>
            </xsl:when>
            <!-- an unnamed (internal) track -->
            <xsl:otherwise>
                <span class="{$class} anno"><i>hidden built-in "<b>Black</b>" track</i></span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- -->
    <xsl:template name="show-track-state-locked">
        <xsl:param name="mlt-track-idx"/>

        <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]"/>
        <xsl:variable name="track" select="/mlt/playlist[@id=$track-ref/@producer]"/>

        <!-- Locked? -->
        <xsl:choose>
            <xsl:when test="$track/property[@name='kdenlive:locked_track']=1">
                <i class="fix-fa fa fa-lock anno-locked" aria-hidden="true" title="locked"/>&#160;
            </xsl:when>
            <xsl:otherwise>
                <i class="fix-fa fa fa-unlock anno-unlocked" aria-hidden="true" title="unlocked"/>&#160;
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- -->
    <xsl:template name="show-track-state-hidden">
        <xsl:param name="mlt-track-idx"/>

        <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]"/>
        <xsl:variable name="hide" select="$track-ref/@hide"/>
        <xsl:variable name="track" select="/mlt/playlist[@id=$track-ref/@producer]"/>

        <!-- Hidden video? -->
        <xsl:choose>
            <xsl:when test="$track/property[@name='kdenlive:audio_track']">
                <!-- show spacer -->
                <span class="fix-fa">&#160;</span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$hide='video' or $hide='both'">
                        <i class="fix-fa fa fa-eye-slash anno-hidden" aria-hidden="true" title="hidden"/>&#160;
                    </xsl:when>
                    <xsl:otherwise>
                        <i class="fix-fa fa fa-eye anno-visible" aria-hidden="true" title="visible"/>&#160;
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- -->
    <xsl:template name="show-track-state-muted">
        <xsl:param name="mlt-track-idx"/>

        <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]"/>
        <xsl:variable name="hide" select="$track-ref/@hide"/>
        <xsl:variable name="track" select="/mlt/playlist[@id=$track-ref/@producer]"/>

        <!-- Muted? -->
        <xsl:choose>
            <xsl:when test="$hide='audio' or $hide='both'">
                <span class="fix-fa anno-muted" aria-hidden="true" title="muted"><i class="fa fa-volume-off"/>&#215;</span>&#160;
            </xsl:when>
            <xsl:otherwise>
                <i class="fix-fa fa fa-volume-up anno-audible" aria-hidden="true" title="audible"/>&#160;
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- -->
    <xsl:template name="show-track-state-transparent">
        <xsl:param name="mlt-track-idx"/>
        <xsl:param name="class" select="fix-fa"/>

        <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]"/>
        <xsl:variable name="track" select="/mlt/playlist[@id=$track-ref/@producer]"/>

       <!-- Video track compositing? -->
        <xsl:choose>
            <xsl:when test="$track/property[@name='kdenlive:audio_track']">
                <!-- show spacer -->
                <span class="{$class}">&#160;</span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <!-- this project seems to use old track-wise compositing -->
                    <xsl:when test="$timeline-compositing-mode = 'track'">
                        <!-- automatic composition needs an excplit invitation! -->
                        <xsl:choose>
                            <xsl:when test="$track/@id = 'black_track'">
                                <!-- don't show state icon for built-in track -->
                                <span class="{$class}"/>
                            </xsl:when>
                            <xsl:when test="$track/property[@name='kdenlive:composite']=1">
                                <span class="{$class}"><xsl:call-template name="transparent-track-icon"/></span>
                            </xsl:when>
                            <xsl:otherwise>
                                <span class="{$class}"><xsl:call-template name="opaque-track-icon"/></span>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$timeline-compositing-mode = 'none'">
                        <!-- none: we show no compositing state/control icon then -->
                        <!-- show spacer instead -->
                        <span class="{$class}">&#160;</span>
                    </xsl:when>
                    <!-- new timeline-wise track compositing modes -->
                    <xsl:otherwise>
                        <span class="{$class}"><xsl:call-template name="transparent-track-icon"/></span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- -->
    <xsl:template name="show-track-state-effects">
        <xsl:param name="mlt-track-idx"/>

        <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]"/>
        <xsl:variable name="track-playlist" select="/mlt/playlist[@id=$track-ref/@producer]"/>

        <xsl:choose>
            <xsl:when test="$mlt-track-idx &gt; 0">
                <!-- Placeholder for now -->
                <span class="fix-fa"><i class="fa fa-star-o anno"/></span>
            </xsl:when>
            <xsl:otherwise>
                <!-- Spacer -->
                <span class="fix-fa">&#160;</span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- Calculate total length of a track in frames, based on clips -->
    <xsl:template name="calc-track-length">
        <xsl:param name="mlt-track-idx"/>

        <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]/@producer"/>
        <xsl:variable name="track-playlist" select="/mlt/playlist[@id=$track-ref]"/>
        <xsl:variable name="clips" select="$track-playlist/entry"/>

        <xsl:variable name="s" select="sum($track-playlist/blank/@length)"/>
        <xsl:variable name="i" select="sum($clips/@in)"/>
        <xsl:variable name="o" select="sum($clips/@out)"/>
        <!-- clip/entry lengths are actually out-in+1, so we need to correct the
             sums calculated from outs-ins...
          -->
        <xsl:variable name="c" select="count($clips)"/>
        <xsl:value-of select="($o - $i) + $c + $s"/>
    </xsl:template>


    <xsl:template name="max-timeline-length">
        <xsl:param name="mlt-track-idx" select="1"/>

        <xsl:variable name="transitions-track-len">
            <xsl:call-template name="calc-track-transitions-end">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="clips-track-len">
            <xsl:call-template name="calc-track-length">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="len">
            <xsl:choose>
                <xsl:when test="$clips-track-len &gt;= $transitions-track-len">
                    <xsl:value-of select="$clips-track-len"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$transitions-track-len"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$mlt-track-idx &lt; $num-timeline-tracks">
                <xsl:variable name="maxlen">
                    <xsl:call-template name="max-timeline-length">
                        <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx + 1"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$maxlen > $len"><xsl:value-of select="$maxlen"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="$len"/></xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$len"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="show-timeline-length">
        <xsl:call-template name="show-timecode">
            <xsl:with-param name="frames">
                <xsl:call-template name="max-timeline-length"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <!-- Spacer for -->
    <xsl:template name="show-track-state-spacer">
        <span class="fix-fa"/>
    </xsl:template>


    <!-- Render track properties, such as track type, name, hidden, locked, muted,
         compositing, et cetera.

         Parameters:
         * track-idx: the 0-based (MLT) track index
      -->
    <xsl:template name="show-track-info">
        <xsl:param name="mlt-track-idx"/>

        <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]/@producer"/>
        <xsl:variable name="track-playlist" select="/mlt/playlist[@id=$track-ref]"/>

        <xsl:call-template name="show-track-icon">
            <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
        </xsl:call-template>

        <xsl:call-template name="show-track-title">
            <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
        </xsl:call-template>

        <span class="track-states">
            <xsl:call-template name="show-track-state-locked">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>

            <xsl:call-template name="show-track-state-muted">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>

            <xsl:call-template name="show-track-state-hidden">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>

            <xsl:call-template name="show-track-state-transparent">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>

            <xsl:call-template name="show-track-state-effects">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>
        </span>

        <!-- calculate total track length on the basis of clips and
             transitions
          -->
        <span class="track-length">
            <xsl:call-template name="track-total-length-timecode">
                <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx"/>
            </xsl:call-template>
        </span>

        <!-- internal information -->
        <span class="anno-id"> (<i>track id: "<xsl:value-of select="$track-ref"/>", index: <xsl:value-of select="$mlt-track-idx"/></i>)</span>
    </xsl:template>


    <!-- recursive function for finding the first video track -->
    <xsl:template name="find-lowest-video-track">
        <xsl:param name="mlt-track-idx" select="1"/>

        <xsl:if test="$mlt-track-idx &lt; $num-timeline-tracks">
            <xsl:variable name="track-ref" select="$timeline-tracks[$mlt-track-idx+1]"/>
            <xsl:variable name="track" select="/mlt/playlist[@id=$track-ref/@producer]"/>

            <xsl:choose>
                <!-- audio-only track? search on! -->
                <xsl:when test="$track/property[@name='kdenlive:audio_track']">
                    <xsl:call-template name="find-lowest-video-track">
                        <xsl:with-param name="mlt-track-idx" select="$mlt-track-idx + 1"/>
                    </xsl:call-template>
                </xsl:when>
                <!-- try next upper track -->
                <xsl:otherwise><xsl:value-of select="$mlt-track-idx"/></xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>


    <xsl:variable name="timeline-lowest-video-track">
        <xsl:call-template name="find-lowest-video-track"/>
    </xsl:variable>




    <!-- -->
    <xsl:template name="show-timecode">
        <xsl:param name="frames"/>

        <xsl:variable name="fps" select="round(/mlt/profile/@frame_rate_num div /mlt/profile/@frame_rate_den)"/>

        <xsl:variable name="ff" select="format-number($frames mod $fps, '00')"/>
        <xsl:variable name="ss" select="format-number(floor($frames div $fps) mod 60, '00')"/>
        <xsl:variable name="mm" select="format-number(floor(($frames div $fps) div 60) mod 60, '00')"/>
        <xsl:variable name="hh" select="format-number(floor(($frames div $fps) div 3600), '00')"/>

        <tt><xsl:value-of select="$hh"/>:<xsl:value-of select="$mm"/>:<xsl:value-of select="$ss"/>:<xsl:value-of select="$ff"/></tt>
        <!--(<xsl:value-of select="$frames"/>)-->
    </xsl:template>


    <!-- Renders a clip icon depending on the clip's type. The following clip icons are
         differentiated:
         * video clip (this is also the fallback in case we don't find a more specific icon)
         * audio-only clip
         * title clip
         * image clip
         * color clip
         * internal/hidden/built-in clip - such as the "black" clip in particular.

         The parameter(s) of this template are as follows:
         * param clipid: the clip id of the <producer> representing the clip. This producer
             encapsulates additional information, depending on the type of clip.

      -->
    <xsl:template name="clip-icon">
        <xsl:param name="clipid"/>
        <xsl:choose>
            <!-- special case: built-in "black" clip -->
            <xsl:when test="$clipid='black'">
                <span class="anno"><i class="fa fa-eye-slash" aria-hidden="true" title="builtin black clip"/>&#160;</span>
            </xsl:when>
            <!-- all other non built-in clips -->
            <xsl:otherwise>
                <!-- what kind of clip do we have here? -->
                <xsl:choose>
                    <!-- audio clip that has no video stream -->
                    <xsl:when test="property[@name='video_index']/text()='-1'">
                        <xsl:call-template name="audio-clip-icon"/>&#160;
                    </xsl:when>
                    <!-- an image clip or clip sequence -->
                    <xsl:when test="property[@name='mlt_service']/text()='pixbuf'">
                        <!-- the difference between a single image and an image sequence
                             can be told from the way the resource property. For image
                             sequences, the resource is specially crafted, starting with
                             .all. instead of a filename.
                          -->
                        <xsl:choose>
                            <xsl:when test="starts-with(replace(property[@name='resource'],'.*/',''),'.all.')">
                                <xsl:call-template name="image-sequence-clip-icon"/>&#160;
                            </xsl:when>
                            <xsl:otherwise>
                                <i class="fa fa-picture-o" aria-hidden="true" title="image clip"/>&#160;
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="property[@name='mlt_service']/text()='qimage'">
                        <xsl:call-template name="image-clip-icon"/>&#160;
                    </xsl:when>
                    <!-- Kdenlive title clip -->
                    <xsl:when test="property[@name='mlt_service']/text()='kdenlivetitle'">
                        <xsl:call-template name="title-clip-icon"/>&#160;
                    </xsl:when>
                    <!-- MLT color clip -->
                    <xsl:when test="property[@name='mlt_service']/text()='color'">
                        <xsl:call-template name="color-clip-icon"/>&#160;
                    </xsl:when>
                    <!-- MLT generators -->
                        <!-- t.b.d. -->
                    <!-- everything else, that is, a video clip (or so we think) -->
                    <xsl:otherwise>
                        <xsl:call-template name="av-clip-icon"/>&#160;
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- -->
    <xsl:template name="list-all-clips">
        <xsl:variable name="folders" select="/mlt/playlist[@id='main bin']/property[starts-with(@name,'kdenlive:folder.')]"/>

        <ul class="project-clips">
            <xsl:for-each select="/mlt/producer">
                <!-- The really messy part here is that we want to sort based on the
                     "names" of the clips. However, if no specific name has been set,
                     then Kdenlive takes the name+ext of a clip without its path as
                     its default name. In our hack to simplify the sorting expression
                     we thus simply concatenate the clip name (which can be empty) with
                     the name+ext of the clip filename.
                  -->
                <xsl:sort select="concat(property[@name='kdenlive:clipname'],replace(property[@name='resource'],'.*/',''),property[@name='resource'])" data-type="text" order="ascending"/>
                <xsl:variable name="clipid" select="@id"/>
                <xsl:if test="not(contains($clipid,'_'))">
                    <li>
                        <xsl:call-template name="clip-icon">
                            <xsl:with-param name="clipid" select="$clipid"/>
                        </xsl:call-template>
                        <xsl:variable name="clipname">
                            <xsl:choose>
                                <xsl:when test="property[@name='kdenlive:clipname']">
                                    <xsl:value-of select="property[@name='kdenlive:clipname']"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="replace(property[@name='resource'],'.*/','')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <b><xsl:value-of select="$clipname"/></b>:

                        <xsl:if test="property[@name='kdenlive:folderid']">
                            <xsl:variable name="foldersuffix" select="concat('.',property[@name='kdenlive:folderid'])"/>
                            <xsl:variable name="folder" select="$folders[substring(@name,string-length(@name) - string-length($foldersuffix) + 1)=$foldersuffix]"/>
                            (<i>length:
                                <xsl:call-template name="show-timecode">
                                    <xsl:with-param name="frames" select="@out"/>
                                </xsl:call-template>,<xsl:text> </xsl:text>
                            from folder</i>: <b><xsl:value-of select="$folder/text()"/></b>)
                        </xsl:if>

                        producer id: <xsl:value-of select="@id"/>,

                        length: <xsl:call-template name="show-timecode"><xsl:with-param name="frames" select="@out"/></xsl:call-template>,<xsl:text> </xsl:text>
                    </li>
                </xsl:if>
            </xsl:for-each>
        </ul>
    </xsl:template>


    <xsl:include href="kpa-internal-video-compositing.xsl"/>
    <xsl:include href="kpa-internal-audio-mixing.xsl"/>

</xsl:stylesheet>
