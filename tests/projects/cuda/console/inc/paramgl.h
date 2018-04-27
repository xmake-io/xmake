/*
 * Copyright 1993-2013 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

/*
   ParamListGL
   - class derived from ParamList to do simple OpenGL rendering of a parameter list
   sgg 8/2001
*/

#ifndef PARAMGL_H
#define PARAMGL_H

#if defined(__APPLE__) || defined(MACOSX)
#include <GLUT/glut.h>
#else
#include <GL/freeglut.h>
#endif

#include <string.h>
#include <param.h>

inline void beginWinCoords(void)
{
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    glTranslatef(0.0, (GLfloat)(glutGet(GLUT_WINDOW_HEIGHT) - 1.0), 0.0);
    glScalef(1.0, -1.0, 1.0);

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0, glutGet(GLUT_WINDOW_WIDTH), 0, glutGet(GLUT_WINDOW_HEIGHT), -1, 1);

    glMatrixMode(GL_MODELVIEW);
}

inline void endWinCoords(void)
{
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();

    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
}

inline void glPrint(int x, int y, const char *s, void *font)
{
    glRasterPos2f((GLfloat)x, (GLfloat)y);
    int len = (int) strlen(s);

    for (int i = 0; i < len; i++)
    {
        glutBitmapCharacter(font, s[i]);
    }
}

inline void glPrintShadowed(int x, int y, const char *s, void *font, float *color)
{
    glColor3f(0.0, 0.0, 0.0);
    glPrint(x-1, y-1, s, font);

    glColor3fv((GLfloat *) color);
    glPrint(x, y, s, font);
}

class ParamListGL : public ParamList
{
    public:
        ParamListGL(const char *name = "") :
            ParamList(name),
            m_active(true),
            m_text_color_selected(1.0, 1.0, 1.0),
            m_text_color_unselected(0.75, 0.75, 0.75),
            m_text_color_shadow(0.0, 0.0, 0.0),
            m_bar_color_outer(0.25, 0.25, 0.25),
            m_bar_color_inner(1.0, 1.0, 1.0)
        {
            m_font = (void *) GLUT_BITMAP_9_BY_15; // GLUT_BITMAP_8_BY_13;
            m_font_h = 15;
            m_bar_x = 260;
            m_bar_w = 250;
            m_bar_h = 10;
            m_bar_offset = 5;
            m_text_x = 5;
            m_separation = 15;
            m_value_x = 200;
            m_start_x = 0;
            m_start_y = 0;
        }

        void Render(int x, int y, bool shadow = false)
        {
            beginWinCoords();

            m_start_x = x;
            m_start_y = y;

            for (std::vector<ParamBase *>::const_iterator p = m_params.begin(); p != m_params.end(); ++p)
            {
                if ((*p)->IsList())
                {
                    ParamListGL *list = (ParamListGL *)(*p);
                    list->Render(x+10, y);
                    y += m_separation*list->GetSize();
                }
                else
                {
                    if (p == m_current)
                    {
                        glColor3fv(&m_text_color_selected.r);
                    }
                    else
                    {
                        glColor3fv(&m_text_color_unselected.r);
                    }

                    if (shadow)
                    {
                        glPrintShadowed(x + m_text_x, y + m_font_h, (*p)->GetName().c_str(), m_font, (p == m_current) ? &m_text_color_selected.r : &m_text_color_unselected.r);
                        glPrintShadowed(x + m_value_x, y + m_font_h, (*p)->GetValueString().c_str(), m_font, (p == m_current) ? &m_text_color_selected.r : &m_text_color_unselected.r);
                    }
                    else
                    {
                        glPrint(x + m_text_x, y + m_font_h, (*p)->GetName().c_str(), m_font);
                        glPrint(x + m_value_x, y + m_font_h, (*p)->GetValueString().c_str(), m_font);
                    }

                    glColor3fv((GLfloat *) &m_bar_color_outer.r);
                    glBegin(GL_LINE_LOOP);
                    glVertex2f((GLfloat)(x + m_bar_x)          , (GLfloat)(y + m_bar_offset));
                    glVertex2f((GLfloat)(x + m_bar_x + m_bar_w), (GLfloat)(y + m_bar_offset));
                    glVertex2f((GLfloat)(x + m_bar_x + m_bar_w), (GLfloat)(y + m_bar_offset + m_bar_h));
                    glVertex2f((GLfloat)(x + m_bar_x)          , (GLfloat)(y + m_bar_offset + m_bar_h));
                    glEnd();

                    glColor3fv((GLfloat *) &m_bar_color_inner.r);
                    glRectf((GLfloat)(x + m_bar_x), (GLfloat)(y + m_bar_offset + m_bar_h), (GLfloat)(x + m_bar_x + ((m_bar_w-1)*(*p)->GetPercentage())), (GLfloat)(y + m_bar_offset + 1));

                    y += m_separation;
                }
            }

            endWinCoords();
        }

        bool Mouse(int x, int y, int button=GLUT_LEFT_BUTTON, int state=GLUT_DOWN)
        {
            if ((y < m_start_y) || (y > (int)(m_start_y + (m_separation * m_params.size()) - 1)))
            {
                m_active = false;
                return false;
            }

            m_active = true;

            int i = (y - m_start_y) / m_separation;

            if ((button==GLUT_LEFT_BUTTON) && (state==GLUT_DOWN))
            {
#if defined(__GNUC__) && (__GNUC__ < 3)
                m_current = &m_params[i];
#else

                // MJH: workaround since the version of vector::at used here is non-standard
                for (m_current = m_params.begin(); m_current != m_params.end() && i > 0; m_current++, i--) ;

                //m_current = (std::vector<ParamBase *>::const_iterator)&m_params.at(i);
#endif

                if ((x > m_bar_x) && (x < m_bar_x + m_bar_w))
                {
                    Motion(x, y);
                }
            }

            return true;
        }

        bool Motion(int x, int y)
        {
            if ((y < m_start_y) || (y > m_start_y + (m_separation * (int)m_params.size()) - 1))
            {
                return false;
            }

            if (x < m_bar_x)
            {
                (*m_current)->SetPercentage(0.0);
                return true;
            }

            if (x > m_bar_x + m_bar_w)
            {
                (*m_current)->SetPercentage(1.0);
                return true;
            }

            (*m_current)->SetPercentage((x-m_bar_x) / (float) m_bar_w);
            return true;
        }

        void Special(int key, int x, int y)
        {
            if (!m_active)
                return;

            switch (key)
            {
                case GLUT_KEY_DOWN:
                    Increment();
                    break;

                case GLUT_KEY_UP:
                    Decrement();
                    break;

                case GLUT_KEY_RIGHT:
                    GetCurrent()->Increment();
                    break;

                case GLUT_KEY_LEFT:
                    GetCurrent()->Decrement();
                    break;

                case GLUT_KEY_HOME:
                    GetCurrent()->Reset();
                    break;

                case GLUT_KEY_END:
                    GetCurrent()->SetPercentage(1.0);
                    break;
            }

            glutPostRedisplay();
        }

        void SetFont(void *font, int height)
        {
            m_font = font;
            m_font_h = height;
        }

        void SetSelectedColor(float r, float g, float b)
        {
            m_text_color_selected = Color(r, g, b);
        }
        void SetUnSelectedColor(float r, float g, float b)
        {
            m_text_color_unselected = Color(r, g, b);
        }
        void SetBarColorInner(float r, float g, float b)
        {
            m_bar_color_inner = Color(r, g, b);
        }
        void SetBarColorOuter(float r, float g, float b)
        {
            m_bar_color_outer = Color(r, g, b);
        }

        void SetActive(bool b)
        {
            m_active = b;
        }

    private:
        void *m_font;
        int m_font_h;       // font height

        int m_bar_x;        // bar start x position
        int m_bar_w;        // bar width
        int m_bar_h;        // bar height
        int m_text_x;       // text start x position
        int m_separation;   // bar separation in y
        int m_value_x;      // value text x position
        int m_bar_offset;   // bar offset in y

        int m_start_x, m_start_y;

        bool m_active;

        struct Color
        {
            Color(float _r, float _g, float _b)
            {
                r = _r;
                g = _g;
                b = _b;
            }
            float r, g, b;
        };

        Color m_text_color_selected;
        Color m_text_color_unselected;
        Color m_text_color_shadow;
        Color m_bar_color_outer;
        Color m_bar_color_inner;
};

#endif
